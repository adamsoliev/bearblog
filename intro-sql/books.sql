CREATE TABLE books (
  book_id            bigint PRIMARY KEY,
  title              text        NOT NULL,
  authors            text        NOT NULL,
  average_rating     numeric(3,2) NOT NULL CHECK (average_rating BETWEEN 0 AND 5),
  isbn               text,                        -- keep as text (leading zeros, X, hyphens)
  isbn13             text,
  language_code      text,
  num_pages          integer CHECK (num_pages >= 0),
  ratings_count      integer CHECK (ratings_count >= 0),
  text_reviews_count integer CHECK (text_reviews_count >= 0),
  publication_date   date,
  publisher          text
);

-- is this necessary?
SET datestyle = 'ISO, MDY';

-- dataset: https://www.kaggle.com/datasets/jealousleopard/goodreadsbooks
-- download it and export it to ~/path/to/books.csv
-- multipass transfer ~/path/to/books.csv instance-name:/tmp/
copy books (
    book_id, title, authors, average_rating, isbn, isbn13, language_code,
    num_pages, ratings_count, text_reviews_count, publication_date, publisher
)
from '/tmp/books.csv'
with (format csv, header true, DELIMITER ','); 

/*
-- 'extra data after last expected column' issue
-- finds lines 3350,4704,5879,8981
    python3 - <<'PY'
    import csv, sys
    path = "/tmp/books.csv"; expected = 12
    with open(path, newline='', encoding='utf-8') as f:
        for i, row in enumerate(csv.reader(f), start=1):
            if len(row) != expected:
                print(f"Line {i}: {len(row)} cols ->", row)
    PY

-- remove lines 3350,4704,5879,8981
    sed -i -e '3350d' -e '4704d' -e '5879d' -e '8981d' /tmp/books.csv
*/

/*
-- 'date/time field value out of range: "11/31/2000"'
-- checks 11th columns and for any invalid date, rolls the day back until it’s valid
    python3 - <<'PY'
    import csv
    from datetime import datetime

    infile  = "/tmp/books.csv"
    outfile = "/tmp/books_clean.csv"
    date_col_idx = 10   # zero-based index; publication_date is the 11th column

    def fix_date(s):
        s = s.strip()
        if not s:
            return ""
        for fmt in ("%m/%d/%Y", "%m-%d-%Y", "%Y-%m-%d"):
            try:
                dt = datetime.strptime(s, fmt)
                return dt.strftime("%m/%d/%Y")
            except ValueError:
                continue
        # try repairing impossible days (e.g., 11/31/2000 → 11/30/2000)
        parts = s.replace('-', '/').split('/')
        if len(parts) == 3:
            m, d, y = parts
            try:
                m, d, y = int(m), int(d), int(y)
                while True:
                    try:
                        dt = datetime(y, m, d)
                        return dt.strftime("%m/%d/%Y")
                    except ValueError:
                        d -= 1
                        if d <= 0:
                            return ""
            except Exception:
                return ""
        return ""

    with open(infile, newline='', encoding='utf-8') as fin, \
        open(outfile, 'w', newline='', encoding='utf-8') as fout:
        reader = csv.reader(fin)
        writer = csv.writer(fout)
        header = next(reader, None)
        if header:
            writer.writerow(header)
        for row in reader:
            if len(row) > date_col_idx:
                row[date_col_idx] = fix_date(row[date_col_idx])
            writer.writerow(row)

    print("Clean file written to", outfile)
    PY
*/

copy books (
    book_id, title, authors, average_rating, isbn, isbn13, language_code,
    num_pages, ratings_count, text_reviews_count, publication_date, publisher
)
from '/tmp/books_clean.csv'
with (format csv, header true, DELIMITER ','); 