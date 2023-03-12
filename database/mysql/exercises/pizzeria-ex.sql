-- relational algebra exercises

select * from person;

select * from frequents;

select * from eats;

select * from serves;


-- a. find all pizzerias frequented by at least one person under the
-- age of 18.

-- person under the age of 18

select P.* from person P
where P.age < 18
;

-- all pizzerias frequented

select F.* from frequents F;

-- final

select F.pizzeria from frequents F
left join person P on F.name = P.name
where P.age < 18
;




-- b. Find the names of all females who eat either mushroom or
-- pepperoni pizza (or both).

-- all females

select P.* from person P
where P.gender = 'female'
;


-- eat mushroom or pepperoni

select E.* from eats E
where E.pizza in ('mushroom', 'pepperoni')
;

-- final

select distinct P.name from person P
left join eats E on P.name = E.name
where P.gender = 'female'
	and E.pizza in ('mushroom', 'pepperoni')
;





-- c. Find the names of all females who eat both mushroom and pepperoni pizza.

-- all females

select * from person P
where P.gender = 'female'
;

-- who eat both mushroom and pepperoni
select name, count(pizza) N from eats
where pizza in ('mushroom', 'pepperoni')
group by name having N = 2
;

-- final

select distinct M.name from
(
	select distinct P.name from person P, eats E
	where P.name = E.name and P.gender = 'female' and E.pizza = 'mushroom'
) M
inner join
(
	select distinct P.name from person P, eats E
	where P.name = E.name and P.gender = 'female' and E.pizza = 'pepperoni'
) P1 on M.name = P1.name
;

select E.name
from (
		 			select name, count(pizza) N from eats
		  	  where pizza in ('mushroom', 'pepperoni')
					group by name having N = 2
		 ) E
inner join person P on E.name = P.name
where  P.gender = 'female'
;



-- d. Find all pizzerias that serve at least one pizza that Amy eats
-- for less than $10.00.

-- the pizzas less than $10.00

select S.* from serves S
where S.price < 10
;

-- the pizzas that Amy eats

select E.* from eats E
where E.name = 'Amy'
;

-- final

select distinct S.pizzeria from
(
	select E.pizza from eats E
	where E.name = 'Amy'
) E1, serves S
where E1.pizza = S.pizza and S.price < 10
;


select S.pizzeria from serves S
inner join eats E on S.pizza = E.pizza
where S.price < 10 and E.name = 'Amy'
;

-- e. Find all pizzerias that are frequented by only females or only males.

select P.*, F.pizzeria from person P
inner join frequents F on P.name = F.name
;

-- female
select distinct F.pizzeria from person P, frequents F
where P.gender = 'female' and P.name = F.name
;

-- male
select distinct F.pizzeria from person P, frequents F
where P.gender = 'male' and P.name = F.name
;


select F.pizzeria,
			 sum(if(P.gender='female', 1, 0)) female,
			 sum(if(P.gender='male', 1, 0)) male
from frequents F, person P
where F.name = P.name
group by F.pizzeria
having female = 0 or male = 0
;


-- https://www.cbcb.umd.edu/confcour/Spring2011/CMSC424/Relational_algebra.pdf

-- EOF
