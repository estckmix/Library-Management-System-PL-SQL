-- Step 1: Create tables to store book details, member information, and borrowing details
CREATE TABLE books (
    book_id          NUMBER PRIMARY KEY,
    title            VARCHAR2(100),
    author           VARCHAR2(100),
    copies_available NUMBER
);

CREATE TABLE members (
    member_id    NUMBER PRIMARY KEY,
    name         VARCHAR2(100),
    contact_info VARCHAR2(100)
);

CREATE TABLE borrowed_books (
    borrow_id   NUMBER PRIMARY KEY,
    book_id     NUMBER
        REFERENCES books ( book_id ),
    member_id   NUMBER
        REFERENCES members ( member_id ),
    borrow_date DATE,
    return_date DATE
);

-- Step 2: Procedure to add a new book
CREATE OR REPLACE PROCEDURE add_book (
    p_book_id NUMBER,
    p_title   VARCHAR2,
    p_author  VARCHAR2,
    p_copies  NUMBER
) IS
BEGIN
    INSERT INTO books (
        book_id,
        title,
        author,
        copies_available
    ) VALUES ( p_book_id,
               p_title,
               p_author,
               p_copies );

    dbms_output.put_line('Book added successfully.');
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error while adding book: ' || sqlerrm);
END;
/

-- Step 3: Procedure to update member details
CREATE OR REPLACE PROCEDURE update_member (
    p_member_id    NUMBER,
    p_name         VARCHAR2,
    p_contact_info VARCHAR2
) IS
BEGIN
    UPDATE members
    SET
        name = p_name,
        contact_info = p_contact_info
    WHERE
        member_id = p_member_id;

    IF SQL%rowcount = 0 THEN
        dbms_output.put_line('No member found with the given ID.');
    ELSE
        dbms_output.put_line('Member details updated successfully.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error while updating member: ' || sqlerrm);
END;
/

-- Step 4: Procedure to borrow a book
CREATE OR REPLACE PROCEDURE borrow_book (
    p_borrow_id   NUMBER,
    p_book_id     NUMBER,
    p_member_id   NUMBER,
    p_borrow_date DATE
) IS
    v_copies NUMBER;
BEGIN
    -- Check if the book is available
    SELECT
        copies_available
    INTO v_copies
    FROM
        books
    WHERE
        book_id = p_book_id;

    IF v_copies > 0 THEN
        -- Insert borrowing details
        INSERT INTO borrowed_books (
            borrow_id,
            book_id,
            member_id,
            borrow_date
        ) VALUES ( p_borrow_id,
                   p_book_id,
                   p_member_id,
                   p_borrow_date );
        -- Decrease the number of available copies
        UPDATE books
        SET
            copies_available = copies_available - 1
        WHERE
            book_id = p_book_id;

        dbms_output.put_line('Book borrowed successfully.');
    ELSE
        dbms_output.put_line('Book is not available.');
    END IF;

EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('Book not found.');
    WHEN OTHERS THEN
        dbms_output.put_line('Error while borrowing book: ' || sqlerrm);
END;
/

-- Step 5: Procedure to return a book
CREATE OR REPLACE PROCEDURE return_book (
    p_borrow_id   NUMBER,
    p_return_date DATE
) IS
    v_book_id NUMBER;
BEGIN
    -- Check if the borrowing record exists
    SELECT
        book_id
    INTO v_book_id
    FROM
        borrowed_books
    WHERE
        borrow_id = p_borrow_id;
    -- Update the return date
    UPDATE borrowed_books
    SET
        return_date = p_return_date
    WHERE
        borrow_id = p_borrow_id;
    -- Increase the number of available copies
    UPDATE books
    SET
        copies_available = copies_available + 1
    WHERE
        book_id = v_book_id;

    dbms_output.put_line('Book returned successfully.');
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('Borrowing record not found.');
    WHEN OTHERS THEN
        dbms_output.put_line('Error while returning book: ' || sqlerrm);
END;
/

-- Step 6: Procedure to generate a report of borrowed books
CREATE OR REPLACE PROCEDURE generate_borrowed_books_report IS
BEGIN
    dbms_output.put_line('Borrowed Books Report:');
    dbms_output.put_line('Borrow ID | Book Title | Member Name | Borrow Date | Return Date');
    FOR rec IN (
        SELECT
            b.borrow_id,
            bk.title,
            m.name,
            b.borrow_date,
            b.return_date
        FROM
                 borrowed_books b
            JOIN books   bk ON b.book_id = bk.book_id
            JOIN members m ON b.member_id = m.member_id
    ) LOOP
        dbms_output.put_line(rec.borrow_id
                             || ' | '
                             || rec.title
                             || ' | '
                             || rec.name
                             || ' | '
                             || rec.borrow_date
                             || ' | '
                             || nvl(
            to_char(rec.return_date, 'YYYY-MM-DD'),
            'Not Returned'
        ));
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error generating report: ' || sqlerrm);
END;
/

-- Usage Examples
-- Adding books
BEGIN
    add_book(1, 'The Great Gatsby', 'F. Scott Fitzgerald', 5);
    add_book(2, '1984', 'George Orwell', 3);
END;
/

-- Adding members
INSERT INTO members VALUES ( 1,
                             'Alice',
                             'alice@example.com' );

INSERT INTO members VALUES ( 2,
                             'Bob',
                             'bob@example.com' );

-- Borrowing a book
BEGIN
    borrow_book(1, 1, 1, sysdate);
END;
/

-- Returning a book
BEGIN
    return_book(1, sysdate + 7);
END;
/

-- Generating a borrowed books report
BEGIN
    generate_borrowed_books_report;
END;
/