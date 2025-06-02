CREATE DATABASE library_db;

-- Library Management System

-- Creating Branch Table
CREATE TABLE branch
(
	branch_id	VARCHAR(20) PRIMARY KEY,
	manager_id	VARCHAR(20),
	branch_address	VARCHAR(55),
	contact_no VARCHAR(20)
);

CREATE TABLE employees
(
	emp_id VARCHAR(20) PRIMARY KEY,
	emp_name VARCHAR(20),
	position VARCHAR(25),
	salary	INT,
	branch_id VARCHAR(25) -- FK
);

CREATE TABLE books
(
	isbn VARCHAR(20) PRIMARY KEY,
	book_title VARCHAR(60),	
	category VARCHAR(20),	
	rental_price	FLOAT,
	status	VARCHAR(15),
	author	VARCHAR(25),
	publisher VARCHAR(30)
);

CREATE TABLE members
(
	member_id	VARCHAR(20) PRIMARY KEY,
	member_name	VARCHAR(25),
	member_address	VARCHAR(75),
	reg_date DATE
);

CREATE TABLE issued_status
(
	issued_id VARCHAR(10) PRIMARY KEY,
	issued_member_id VARCHAR(10), -- FK
	issued_book_name VARCHAR(75),
	issued_date	DATE,
	issued_book_isbn VARCHAR(25), -- FK
	issued_emp_id VARCHAR(10) -- FK
);

CREATE TABLE return_status
(
	return_id VARCHAR(10) PRIMARY KEY,	
	issued_id VARCHAR(10),	-- FK
	return_book_name VARCHAR(75),	
	return_date DATE,	
	return_book_isbn VARCHAR(20)
);

-- FOREIGN KEY

ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employees
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued_status
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);

-- Project Tasks

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

 -- Task 2: Update an Existing Member's Address
 
UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;

-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
 
 DELETE FROM issued_status
 WHERE issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT *
FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book

SELECT 
	issued_member_id,
    COUNT(issued_id) total_books_issued
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(issued_id) > 1;

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_counts
AS
SELECT 
	b.book_title,
	b.isbn,
    COUNT(ist.issued_id) no_issued
FROM books b
JOIN
issued_status ist
ON ist.issued_book_isbn = b.isbn
GROUP BY b.book_title, b.isbn;

-- Task 7. Retrieve All Books in a Specific Category:

SELECT *
FROM books
WHERE category = 'Classic';
 
 -- Task 8: Find Total Rental Income by Category:
 
SELECT 
	b.category,
    SUM(b.rental_price) total_rental_income,
    COUNT(*) 
FROM books b
JOIN issued_status ist
ON b.isbn = ist.issued_book_isbn
GROUP BY b.category;

 -- List Members Who Registered in the Last 180 Days:

 SELECT *
 FROM members
 WHERE reg_date >= DATE_SUB(CURDATE(), INTERVAL 180 DAY);
 
 -- List Employees with Their Branch Manager's Name and their branch details:
 
SELECT 
	e.*,
    b.manager_id,
	e2.emp_name manager_name,
    b.branch_address
 FROM employees e
 JOIN branch b
 ON e.branch_id = b.branch_id
 JOIN employees e2
 ON b.manager_id = e2.emp_id;
 
 -- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold($7):
 
 CREATE TABLE books_price_greater_than_7
 AS
 SELECT *
 FROM books
 WHERE rental_price > 7;
 
 -- Task 12: Retrieve the List of Books Not Yet Returned
 
 SELECT 
	DISTINCT i.issued_book_name
 FROM issued_status i
 LEFT JOIN return_status rs
 ON rs.issued_id = i.issued_id
 WHERE rs.return_id IS NULL;
 
-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT 
	ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    DATEDIFF('2024-04-28', ist.issued_date) borrowing_period
FROM issued_status ist
JOIN members m
ON m.member_id = ist.issued_member_id
JOIN books bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs
ON rs.issued_id = ist.issued_id
WHERE 
	rs.return_date IS NULL
	AND
	DATEDIFF('2024-04-28', ist.issued_date)> 30
ORDER BY 1;

-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

-- STORE PROCEDURES
DROP PROCEDURE IF EXISTS add_return_records;
DELIMITER $$
CREATE PROCEDURE add_return_records(
    p_return_id VARCHAR(10),
    p_issued_id VARCHAR(10),
    p_book_quality VARCHAR(15)
)
 
BEGIN
	DECLARE v_isbn VARCHAR(50);
	DECLARE v_book_name VARCHAR(80);
	INSERT INTO return_status(return_id, issued_id, return_date , book_quality)
    VALUES 
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality); 
    SELECT 
		issued_book_isbn,
        issued_book_name
        INTO 
        v_isbn,
        v_book_name
	FROM issued_status
    WHERE issued_id = p_issued_id;
    
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;
    
    SELECT CONCAT('Thank you for returning the book ', v_book_name) AS message;
END $$
DELIMITER ;

-- Calling the function
CALL add_return_records('RS135' , 'IS135', 'Excellent');


-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.


CREATE TABLE branch_reports
	AS
SELECT 
	b.branch_id,
    COUNT(ist.issued_id) number_books_issued,
    COUNT(rs.return_id) number_books_returned,
    SUM(bs.rental_price) total_revenue
FROM issued_status ist
JOIN 
employees e
ON ist.issued_emp_id = e.emp_id
JOIN 
branch b
ON b.branch_id = e.branch_id
LEFT JOIN 
return_status rs
ON rs.issued_id = ist.issued_id
JOIN 
books bs
ON bs.isbn = ist.issued_book_isbn
GROUP BY 1;

-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 14 months.

CREATE TABLE active_members
AS
SELECT *
FROM members
WHERE member_id IN (
SELECT 
	DISTINCT issued_member_id
FROM issued_status
WHERE 
	issued_date BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 14 MONTH) AND CURRENT_DATE
);


-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.


SELECT 
	e.emp_id,
	e.emp_name,
    COUNT(ist.issued_id) number_books_issued,
    e.branch_id
FROM employees e
JOIN issued_status ist
ON e.emp_id = ist.issued_emp_id
GROUP BY 1
ORDER BY  COUNT(ist.issued_id) DESC
LIMIT 3;

-- Task 18: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. Description: Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows: The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

DELIMITER $$

CREATE PROCEDURE issue_book(
	p_issued_id VARCHAR(20),
    p_issued_member_id VARCHAR(20),
    p_issued_book_isbn VARCHAR(50),
    p_issued_emp_id VARCHAR(20))
BEGIN
	DECLARE v_status VARCHAR(10);
	SELECT 
		status
        INTO
        v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;
    
    IF v_status = 'yes' THEN
		INSERT INTO issued_status(issued_id, issued_member_id, issued_date ,issued_book_isbn, issued_emp_id)
		VALUES(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);
		
		UPDATE books
		SET status = 'no'
		WHERE isbn = p_issued_book_isbn;
        SELECT CONCAT('One book records added sucessfully: ', p_issued_book_isbn) AS message;
    ELSE
		SELECT 'Sorry to inform you the book requested is not available' AS message;
	END IF;
END;
$$
DELIMITER ;

CALL issue_book('IS156', 'C108', '978-0-06-025492-6', 'E104');

