# SQL Project: Sales Data
Simple project in SQL that consisted of treating and analyzing a database. Ran using SQLite.


# Treating the data
**1. Populating the `min_price` and `max_price` columns**
```sql
UPDATE produtos
SET 
    max_price = CASE
        WHEN nome_produto = 'Celular' THEN 5000
        WHEN nome_produto = 'Camisa' THEN 200
        WHEN nome_produto = 'Livro de Ficção' THEN 200
        WHEN nome_produto ='Bola de Futebol' THEN 100
        ELSE max_price
    END,
    min_price = CASE
        WHEN nome_produto = 'Celular' THEN 80
        WHEN nome_produto = 'Camisa' THEN 80
        WHEN nome_produto = 'Livro de Ficção' THEN 10
		WHEN nome_produto ='Bola de Futebol' THEN 20
        ELSE min_price
    END

-- Check results.
SELECT nome_produto, min_price, max_price
FROM produtos
GROUP BY nome_produto;
```

**2. Updating prices based on upper and lower bounds**

```sql
--Adjust prices based on min and max prices

UPDATE produtos
SET preco = CASE
	WHEN preco < min_price THEN min_price
    WHEN preco > max_price THEN max_price
    ELSE
    	preco
END
WHERE preco < min_price OR preco > max_price

--Check results
SELECT 
	nome_produto,
    max(preco) AS 'real_max_price',
    max_price,
    min(preco) AS 'real_min_price',
    min_price
FROM produtos
GROUP BY nome_produto
```
