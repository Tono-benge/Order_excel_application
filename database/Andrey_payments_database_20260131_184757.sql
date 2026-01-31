------------- SQLite3 Dump File -------------

-- ------------------------------------------
-- Dump of "Table1"
-- ------------------------------------------

CREATE TABLE "Table1"(
	"ID" Integer PRIMARY KEY AUTOINCREMENT,
	"full_name" Text NOT NULL );


INSERT INTO "Table1" ("ID","full_name") VALUES 
( 1, 'Иван Иванович Петров' ),
( 2, 'Виктор В' ),
( 3, 'Андрей Васильевич' ),
( 4, 'Петр Васильевич' ),
( 12, 'Сергей Сергеевич' ),
( 13, 'Ветренко Дмитрий' );


-- ------------------------------------------
-- Dump of "Table2"
-- ------------------------------------------

CREATE TABLE "Table2"(
	"order_ID" Integer PRIMARY KEY AUTOINCREMENT,
	"order_amount" Real NOT NULL,
	"UserID_Foreign_Key" Integer );


INSERT INTO "Table2" ("order_ID","order_amount","UserID_Foreign_Key") VALUES 
( 1, 7155, 1 ),
( 2, 1700, 2 ),
( 3, 2000, 3 ),
( 4, 2222, 4 ),
( 9, 1758, 12 ),
( 10, 40632.3000000000029104, 13 );


