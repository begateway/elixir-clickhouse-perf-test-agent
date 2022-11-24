CREATE TABLE IF NOT EXISTS cats
(
  uid              String,
  name             String,
  created_at       DateTime64(3) NOT NULL,
  updated_at       DateTime64(3) NOT NULL,
  feeded_at        Nullable(DateTime64(3)),
  number_of_paws   UInt32 NOT NULL,
  number_of_tails  UInt32 NOT NULL,
  age              UInt32 NOT NULL,
  length           Nullable(UInt32),
  weight           Nullable(UInt32),

  column0 Nullable(UInt32),
  column1 Nullable(UInt32),
  column2 Nullable(UInt64),
  column3 Nullable(String),
  column4 Nullable(FixedString(2)),
  column5 Nullable(UInt32),
  column6 Nullable(UInt64),
  column7 Nullable(String),
  column8 Nullable(FixedString(2)),
  column9 Nullable(UInt64),

  column10 Nullable(UInt32),
  column11 Nullable(UInt32),
  column12 Nullable(UInt64),
  column13 Nullable(String),
  column14 Nullable(FixedString(2)),
  column15 Nullable(UInt32),
  column16 Nullable(UInt64),
  column17 Nullable(String),
  column18 Nullable(FixedString(2)),
  column19 Nullable(UInt64),

  column20 Nullable(UInt32),
  column21 Nullable(UInt32),
  column22 Nullable(UInt64),
  column23 Nullable(String),
  column24 Nullable(FixedString(2)),
  column25 Nullable(UInt32),
  column26 Nullable(UInt64),
  column27 Nullable(String),
  column28 Nullable(FixedString(2)),
  column29 Nullable(UInt64),

  column30 Nullable(UInt32),
  column31 Nullable(UInt32),
  column32 Nullable(UInt64),
  column33 Nullable(String),
  column34 Nullable(FixedString(2)),
  column35 Nullable(UInt32),
  column36 Nullable(UInt64),
  column37 Nullable(String),
  column38 Nullable(FixedString(2)),
  column39 Nullable(UInt64),

  column40 Nullable(UInt32),
  column41 Nullable(UInt32),
  column42 Nullable(UInt64),
  column43 Nullable(String),
  column44 Nullable(FixedString(2)),
  column45 Nullable(UInt32),
  column46 Nullable(UInt64),
  column47 Nullable(String),
  column48 Nullable(FixedString(2)),
  column49 Nullable(UInt64),

  column50 Nullable(UInt32),
  column51 Nullable(UInt32),
  column52 Nullable(UInt64),
  column53 Nullable(String),
  column54 Nullable(FixedString(2)),
  column55 Nullable(UInt32),
  column56 Nullable(UInt64),
  column57 Nullable(String),
  column58 Nullable(FixedString(2)),
  column59 Nullable(UInt64)
)
ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY toYYYYMM(created_at)
ORDER BY (uid)
