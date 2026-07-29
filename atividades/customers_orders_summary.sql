create or replace view customers_orders_summary as
select 
    c.id,
    c.name,
    count(o.id) as orders,
    sum(o.total) as total_spent,
    avg(o.total) as average_ticket
from customers c 
left join orders o on 
    o.customer_id = c.id
where 
    o.status = "paid"
group by 
    c.id,
    c.name;