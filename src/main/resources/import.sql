CREATE TABLE projetos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome_projeto VARCHAR(50) NOT NULL,
    tecnologia VARCHAR(30),
    data_criacao DATE
);

-- Insere um dado de teste
INSERT INTO projetos_estudo (nome_projeto, tecnologia, data_criacao)
VALUES ('RDS com Terraform', 'Terraform/AWS', CURDATE());