CREATE TABLE customer (
    id INT NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(120) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE product (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE orders (
    id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (customer_id) REFERENCES customer(id)
);

CREATE TABLE order_line (
    id INT NOT NULL AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES product(id)
);
