--Each of the following case study questions can be answered using a single SQL statement:

--What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price)
from sales s
left join menu m
on s.product_id = m.product_id
group by s.customer_id;

--How many days has each customer visited the restaurant?
select s.customer_id, count(distinct(s.order_date))
from sales s
group by s.customer_id;


--What was the first item from the menu purchased by each customer?
select s.customer_id, min(s.order_date)
from sales s
group by s.customer_id;


--What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id)
from sales s
left join menu m
on s.product_id = m.product_id
group by m.product_name;


--Which item was the most popular for each customer?
WITH CTE
AS
(
SELECT customer_id, product_id, COUNT(product_id) AS cnt, RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS ranking
FROM sales
GROUP BY customer_id, product_id
)
SELECT customer_id, product_name, cnt
FROM CTE c
	JOIN menu m
		ON c.product_id=m.product_id
WHERE ranking=1

--Which item was purchased first by the customer after they became a member?
with cte as (
select s.customer_id, s.product_id, s.order_date, mem.join_date,
RANK() OVER (PARTITION BY order_date order by order_date) as ranking
from sales s
join members mem
on mem.customer_id = s.customer_id
where s.order_date >= mem.join_date
group by customer_id
)
select cte.customer_id, m.product_name
from cte
join menu m
on cte.product_id = m.product_id;

--Which item was purchased just before the customer became a member?
with cte as (
select s.customer_id, s.product_id, s.order_date, mem.join_date
from sales s
join members mem
on mem.customer_id = s.customer_id
where s.order_date < mem.join_date
group by customer_id, product_id
)
select cte.customer_id, m.product_name
from cte
join menu m
on cte.product_id = m.product_id;

--What is the total items and amount spent for each member before they became a member?
with cte as (
select s.customer_id, s.product_id, count(s.product_id) as cnt
from sales s
join members mem
on s.customer_id = mem.customer_id
where s.order_date < mem.join_date
group by s.customer_id, s.product_id
)
select cte.customer_id, sum(cte.cnt * m.price) as amount_spent
from cte
join menu m
on cte.product_id = m.product_id
group by cte.customer_id;

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as (
select s.customer_id, s.product_id, m.product_name,
case when m.product_name not in ('sushi') then count(s.product_id) * m.price
else count(s.product_id) * m.price * 2 end
as points
from sales s
join menu m
on s.product_id = m.product_id
group by s.customer_id, s.product_id, m.product_name
)
select cte.customer_id, sum(cte.points)
from cte
group by cte.customer_id;

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with cte as (
select s.customer_id, s.product_id, count(s.product_id),
case when s.order_date >= mem.join_date and s.order_date <= DATE_ADD(mem.join_date, INTERVAL 7 DAY)
then (count(s.product_id)*m.price)*2
else count(s.product_id)*m.price end
as points
, mem.join_date
from sales s
join members mem
on mem.customer_id = s.customer_id
join menu m
on s.product_id = m.product_id
where s.order_date >= mem.join_date
AND s.order_date < DATE('2021-02-01')
group by customer_id, product_id
)
select cte.customer_id, sum(cte.points)
from cte
group by customer_id;

-- Bonus question one
select s.customer_id, s.order_date, m.product_name, m.price,
case when s.order_date >= mem.join_date then 'Y'
else 'N' end
as member
from sales s
left join menu m
on s.product_id = m.product_id
left join members mem
on s.customer_id = mem.customer_id;

-- Bonus question two
with cte as (
select s.customer_id, s.order_date, m.product_name, m.price,
case when s.order_date >= mem.join_date then 'Y'
else 'N' end
as member
from sales s
left join menu m
on s.product_id = m.product_id
left join members mem
on s.customer_id = mem.customer_id
)
select cte.customer_id, cte.order_date, cte.product_name, cte.price, cte.member,
case when cte.member = 'N' then null
else RANK() OVER (
PARTITION BY cte.customer_id, cte.member
order by cte.customer_id, cte.order_date, cte.product_name asc) end as ranking
from cte;