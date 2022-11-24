-- RPS: 50
insert into cats (
  uid, name, created_at, updated_at,
  number_of_paws, number_of_tails, age, weight,
  column0, column1, column2, column3, column4, column5, column6,
  column10, column11, column12, column13, column14, column15, column16
) VALUES (
  '{uid}', '{name}', '{created_at}', '{updated_at}',
  '{number_of_paws}', '{number_of_tails}', '{age}', '{weight}',
  '{column0}', '{column1}', '{column2}', '{column3}', '{column4}', '{column5}', '{column6}',
  '{column10}', '{column11}', '{column12}', '{column13}', '{column14}', '{column15}', '{column16}'
)

-- RPS: 50
insert into cats (
  uid, name, created_at, updated_at, feeded_at
  number_of_paws, number_of_tails, age, length, weight,
  column0, column1, column2, column3, column4, column5, column6,
  column10, column11, column12, column13, column14, column15, column16,
  column20, column21, column22, column23, column24, column25, column26,
  column30, column31, column32, column33, column34, column35, column36,
  column40, column41, column42, column43, column44, column45, column46,
  column50, column51, column52, column53, column54, column55, column56
) VALUES (
  '{uid}', '{name}', '{created_at}', '{updated_at}', '{feeded_at}',
  '{number_of_paws}', '{number_of_tails}', '{age}', '{length}', '{weight}',
  '{column0}', '{column1}', '{column2}', '{column3}', '{column4}', '{column5}', '{column6}',
  '{column10}', '{column11}', '{column12}', '{column13}', '{column14}', '{column15}', '{column16}'
  '{column20}', '{column21}', '{column22}', '{column23}', '{column24}', '{column25}', '{column26}'
  '{column30}', '{column31}', '{column32}', '{column33}', '{column34}', '{column35}', '{column36}'
  '{column40}', '{column41}', '{column42}', '{column43}', '{column44}', '{column45}', '{column46}'
  '{column50}', '{column51}', '{column52}', '{column53}', '{column54}', '{column55}', '{column56}'
)
