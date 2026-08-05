DELIMITER $$

CREATE PROCEDURE confirm_customer_purchase(IN p_customer_id BIGINT UNSIGNED)
BEGIN
    DECLARE v_cart_id BIGINT UNSIGNED DEFAULT NULL;
    DECLARE v_order_id BIGINT UNSIGNED;
    DECLARE v_item_count BIGINT UNSIGNED DEFAULT 0;
    DECLARE v_updated_count BIGINT UNSIGNED DEFAULT 0;
    DECLARE v_total DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
        FROM customers
        WHERE id = p_customer_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cliente nao encontrado.';
    END IF;

    SELECT id
      INTO v_cart_id
      FROM cart
     WHERE customer_id = p_customer_id
       AND status = 'open'
     ORDER BY id DESC
     LIMIT 1
     FOR UPDATE;

    IF v_cart_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O cliente nao possui carrinho aberto.';
    END IF;

    SELECT COUNT(*), COALESCE(SUM(ci.quantity * p.price), 0)
      INTO v_item_count, v_total
      FROM cart_items AS ci
      JOIN products AS p ON p.id = ci.product_id
     WHERE ci.cart_id = v_cart_id;

    IF v_item_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O carrinho esta vazio.';
    END IF;

    INSERT INTO orders (
        customer_id,
        total,
        status,
        paid_at,
        created_at,
        updated_at
    ) VALUES (
        p_customer_id,
        v_total,
        'paid',
        v_purchased_at,
        v_purchased_at,
        v_purchased_at
    );

    SET v_order_id = LAST_INSERT_ID();

    INSERT INTO order_items (
        order_id,
        product_id,
        product_name,
        product_price,
        quantity,
        created_at,
        updated_at
    )
    SELECT
        v_order_id,
        p.id,
        p.name,
        p.price,
        ci.quantity,
        v_purchased_at,
        v_purchased_at
    FROM cart_items AS ci
    JOIN products AS p ON p.id = ci.product_id
    WHERE ci.cart_id = v_cart_id;

    UPDATE products AS p
    JOIN cart_items AS ci
      ON ci.product_id = p.id
     AND ci.cart_id = v_cart_id
       SET p.stock = p.stock - ci.quantity,
           p.updated_at = v_purchased_at
     WHERE p.stock >= ci.quantity;

    SET v_updated_count = ROW_COUNT();

    IF v_updated_count <> v_item_count THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque insuficiente para um ou mais produtos.';
    END IF;

    DELETE FROM cart_items
    WHERE cart_id = v_cart_id;

    UPDATE cart
       SET status = 'completed',
           updated_at = CURRENT_TIMESTAMP
     WHERE id = v_cart_id;

    COMMIT;

    SELECT
        v_order_id AS order_id,
        p_customer_id AS customer_id,
        v_total AS total,
        v_purchased_at AS purchased_at;
END$$

DELIMITER ;