CREATE TABLE parent (
    id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(120)
);

CREATE TABLE enfant (
    id INT PRIMARY KEY,
    id_papa INT,
    id_maman INT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    FOREIGN KEY (id_papa)  REFERENCES parent(id),
    FOREIGN KEY (id_maman) REFERENCES parent(id)
);

CREATE TABLE sport (
    id INT PRIMARY KEY,
    intitule VARCHAR(50) NOT NULL
);

-- jointure
CREATE TABLE enfant_sport (
    id_sport INT NOT NULL,
    id_enfant INT NOT NULL,
    FOREIGN KEY (id_sport) REFERENCES sport(id),
    FOREIGN KEY (id_enfant) REFERENCES enfant(id)
);