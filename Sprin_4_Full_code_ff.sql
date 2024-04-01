# Elaboració d'un dataframe a partir de CSV. 
# Importació, formateig i Relacions Entitats
Show databases;
use sprint4_db;
show tables;

# Utilización el Wizard para la creación e importación de las tablas desde un CSV
# Manipulación de las tablas y compatibilidad de los campos PK, FK - Es necesario garantizar la 
# compatibilidad de formato entre tablas, si bien detectamos una incidencia en PRODUCTS 
# que resolveremos más tarde, por ello utilizamos el comando SET FOREIGN_KEY_CHECKS = 0

# Creamos índices en tabla transactions
SHOW CREATE TABLE transactions;
ALTER TABLE transactions
ADD INDEX (card_id),
ADD INDEX (business_id),
ADD INDEX (product_ids),
ADD INDEX (user_id);
ALTER TABLE credit_cards
ADD INDEX (user_id);

ALTER TABLE credit_cards
ADD foreign key (user_id) REFERENCES users_ca(id);
ALTER TABLE credit_cards
ADD foreign key (user_id) REFERENCES users_uk(id);
ALTER TABLE credit_cards
ADD foreign key (user_id) REFERENCES users_usa(id);

ALTER TABLE transactions
ADD FOREIGN KEY (business_id) REFERENCES companies(company_id);
ALTER TABLE transactions
ADD FOREIGN KEY(card_id) REFERENCES credit_cards(id);
SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE transactions
ADD FOREIGN KEY(product_ids) REFERENCES products(id);

# Creamos una vista VIEW combinada con UNION de las tablas de usuarios
# Hago este paso previo porque intuio que me va a ser útil en el futuro
CREATE VIEW usuarios_all_countries AS 
SELECT * FROM users_ca
UNION
SELECT * FROM users_uk
UNION
SELECT * FROM users_usa;
# realizamos una comprobación (en principio innecesaria) de que un usuario no esté en varios países.
SELECT id, count(id) FROM usuarios_all_countries
GROUP BY id
HAVING count(id)>1;

# realizamos otra comprobación adicional mediante la cual descubrimos que
# los usuarios 1 y 10  están dados de alta en la tabla users_usa, sin embargo
# jamás han realizado una transacción, por lo que debermos JOIN bajo esta premisa
SELECT *  FROM usuarios_all_countries
ORDER BY id ASC;
SELECT *  FROM transactions
#WHERE user_id =1
ORDER BY user_id ASC;

# SPINT_4, NIVEL_ 1_ EJERCICIO_1
# Usuarios con más de 30 transacciones
SELECT u.id, u.name, u.surname, count(user_id) as contador 
FROM transactions AS t
INNER JOIN usuarios_all_countries as u ON u.id = t.user_id
GROUP BY user_id, u.id, u.name, u.surname
HAVING contador >30 
ORDER BY contador desc;


-- SPRINT_4, NIVEL 1_ EJERCICIO_2
-- Media por IBAN de Donec LTD

-- Primero hacemos una comprobación rutinaria para asegurarnos de que no hay tarjetas duplicadas
-- y que el recuento coincide con las 275 transacciones existentes
SELECT iban, COUNT(iban) AS contador 
FROM credit_cards 
GROUP BY iban 
HAVING contador > 1;

-- Luego, verificamos si hay más de una entrada para Donec y si la especificación coincide con Donec Ltd
SELECT company_id, company_name  
FROM companies 
WHERE company_name LIKE 'Donec%';

-- Finalmente, calculamos la media de las transacciones por IBAN para Donec Ltd
SELECT c.company_name, cd.iban, ROUND(AVG(t.amount), 2) AS media_trans 
FROM transactions AS t
JOIN companies AS c ON c.company_id = t.business_id
JOIN credit_cards AS cd ON cd.id = t.card_id
WHERE c.company_name = 'Donec Ltd'
GROUP BY c.company_name, cd.iban;




# SPRINT_4, NIVEL 2_ EJERCICIO_1
DELETE FROM credit_card_status;
INSERT INTO credit_card_status (card_id, status)
SELECT 
    card_id,
    CASE 
        WHEN SUM(declined) >= 3 THEN 'Inactiva'
        ELSE 'Activa'
    END AS status
FROM (
    SELECT 
        card_id, 
        declined,
        ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS fr
    FROM 
        transactions
) AS last_transactions
WHERE 
    fr <= 3
GROUP BY 
    card_id;
SELECT * FROM credit_card_status;
SELECT COUNT(*) FROM credit_card_status WHERE status = 'Activa';


# SPRINT_4, NIVEL 3_ EJERCICIO_1
# Número de Unidades que se ha vendido cada producto

CREATE TABLE transaction_products_expanded (
    id VARCHAR(250),
    card_id VARCHAR(100),
    business_id VARCHAR(100),
    timestamp TEXT,
    amount DOUBLE,
    declined INT,
    product_id VARCHAR(100), -- Aquí almacenaremos los ID de producto individuales
    user_id INT,
    lat DOUBLE,
    longitude DOUBLE
);

INSERT INTO transaction_products_expanded (id, card_id, business_id, timestamp, amount, declined, product_id, user_id, lat, longitude)
SELECT 
    transactions.id,
    transactions.card_id,
    transactions.business_id,
    transactions.timestamp,
    transactions.amount,
    transactions.declined,
    SUBSTRING_INDEX(SUBSTRING_INDEX(transactions.product_ids, ',', numbers.n), ',', -1) as product_id,
    transactions.user_id,
    transactions.lat,
    transactions.longitude
FROM 
  (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
   SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
   SELECT 9 UNION ALL SELECT 10) numbers INNER JOIN transactions
  ON CHAR_LENGTH(transactions.product_ids) 
     - CHAR_LENGTH(REPLACE(transactions.product_ids, ',', '')) >= numbers.n - 1
ORDER BY 
  transactions.id, 
  numbers.n;

select product_id, p.product_name, count(product_id) as unitats_venudes from transaction_products_expanded as te
join products as p on te.product_id  = p.id
group by product_id
order by p.product_name asc;

select *  from transaction_products_expanded;







# OTRO CÓDIGO AUXILIAR UTILIZADO PARA EL EJERCICIO 
describe transactions;
describe products;
describe credit_cards;
describe companies;
describe users_ca;
describe users_usa;
select * from transactions
where id = '02C6201E-D90A-1859-B4EE-88D2986D3B02';
select * from users_ca;
select * from companies;
select * from products;
select distinct COUNT(id) from transactions;

#Foreign Key  en transactions a companies
ALTER TABLE `transactions` 
ADD CONSTRAINT `fk_company`
  FOREIGN KEY (`business_id`)
  REFERENCES `companies` (`company_id`)
  ON DELETE SET NULL
  ON UPDATE SET NULL;
#Foreign Key para productos
ALTER TABLE `transactions` 
ADD CONSTRAINT `fk_products1`
  FOREIGN KEY (`product_ids`)
  REFERENCES `products` (`id`)
  ON DELETE SET NULL
  ON UPDATE SET NULL;


ALTER TABLE transactions
ADD INDEX (card_id);

ALTER TABLE transactions
ADD INDEX (product_ids);

#Foreing Key para credit_cards
ALTER TABLE transactions
ADD FOREIGN KEY(card_id) REFERENCES credit_cards(id);

#Quitamos restricción en products para poder lanzar la foreign key
SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE transactions
ADD FOREIGN KEY(product_ids) REFERENCES products(id);



  
