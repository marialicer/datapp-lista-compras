WITH tb_lag AS (

    SELECT *,
        LAG(dt_compra) OVER (PARTITION BY produto ORDER BY dt_compra) AS dt_anterior
    FROM compras
    ORDER BY produto, dt_compra

),

tb_avg AS (

    SELECT produto,
        avg(JULIANDAY(dt_compra) - JULIANDAY(dt_anterior)) AS avg_diff_dias

    FROM tb_lag
    GROUP BY produto
),

tb_stats_produto AS (

    SELECT produto, 
        max(dt_compra) AS dt_ultima_compra,
        avg(valor_produto) AS media_valor
    FROM compras
    GROUP BY produto

)

SELECT t1.*,
    t2.avg_diff_dias,
    julianday('now') - julianday(dt_ultima_compra) AS dias_ultima_compra
    
FROM tb_stats_produto AS t1
LEFT JOIN tb_avg AS t2
ON t1.produto = t2.produto

