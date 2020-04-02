USE ???;

DROP TABLE TestTable1;
DROP TABLE TestTable2;
GO

CREATE TABLE TestTable1
(
  Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Val1 INT,
  Val2 FLOAT,
  Val3 FLOAT,
  Str1 NVARCHAR(max),
  Str2 NVARCHAR(max),
  Str3 NVARCHAR(max)
);

CREATE TABLE TestTable2
(
  Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Val INT
);
GO

SET NOCOUNT ON;

DECLARE @Iteration INT;

SET @Iteration = 1;
WHILE @Iteration <= 100000
BEGIN
  INSERT INTO TestTable1 (Val1, Val2, Val3, Str1, Str2, Str3) VALUES (@Iteration, SQRT(@Iteration), LOG(@Iteration), CONVERT(nvarchar(max), @Iteration), CONVERT(nvarchar(max), SQRT(@Iteration)), CONVERT(nvarchar(max), LOG(@Iteration)));

  SET @Iteration = @Iteration + 1
END;

SET @Iteration = 1;
WHILE @Iteration <= 1000
BEGIN
  INSERT INTO TestTable2 (Val) VALUES (@Iteration);

  SET @Iteration = @Iteration + 1
END;


