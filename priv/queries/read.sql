-- RPS: 2
select uid, name, created_at, updated_at,
column0, column1, column2, column3, column4, 
column10, column11, column12, column13, column14, 
column40, column41, column42, column43, column44
from cats
where created_at > '2022-01-01'
and number_of_paws > 6
and weight > 100
order by created_at asc
limit 10;

-- RPS: 1
select uid,
argMax(created_at, updated_at) as _created_at,
max(updated_at) as _updated_at,
argMax(feeded_at, updated_at) as _feeded_at,
argMax(length, updated_at) as _length,
argMax(age, updated_at) as _age
from cats
where created_at >= '2022-01-01'
group by uid
having _length > 10 and _feeded_at > '2022-01-01'
limit 10;

-- RPS: 1
select count(uid) from (
  select uid,
  argMax(weight, updated_at) as _weight
  from cats
  group by uid
  having _weight > 100
);
