# Cumbuquinha Challenge

Minha submissão para o challenge de dev back-end sênior para a Cumbuca.
Implementação de um pequeno banco de dados transacional, persistente e multi-usuário escrito de acordo com as especificações fornecidas!

## Para executar o projeto

Deixei duas opções prontas para execução: nativamente pela linha de comando e por um container do Docker.

  * Rodar nativamente:  
    1. Instale o elixir em sua máquina caso não tenha previamente!
    2.  Abra seu terminal de escolha no diretório do repositório, execute o comando `mix setup` para instalar dependências 
    3.  Execute `mix phx.server` para começar o servidor localmente na porta 4000. isto é:
    [`localhost:4000`](http://localhost:4000) .

  * Rodar por docker-compose
    1. Tenha o docker desktop instalado
    2. Abra no terminal o diretório do projeto
    3. Rode `docker-compose up --build` e o servidor também vai estar aberto em [`localhost:4000`](http://localhost:4000).

## Modo de uso

Para usar o banco de dados do servidor, o servidor recebe requisições por default localmente na porta 4000.
As requests são todos POSTs para o mesmo endpoint, a raiz, não tendo distinção entre os content-types `text/plain` e `x-www-form-urlencoded`.
Uma coisa que acabei descobrindo é que na omissão desse header em um comando cURL, o default se torna `x-www-form-urlencoded`!

O seguinte comando, 
```
curl -L 'http://localhost:4000' -H 'X-Client-Name: A' -d 'SET ABC 1' 
```
é tão válido quanto este:
```
curl --location 'http://localhost:4000' \
--header 'X-Client-Name: A' \
--header 'Content-Type: text/plain' \
--data 'SET ABC teste'
```

**É absolutamente necessário o header `X-Client-Name` para o uso do banco.**

O corpo da request consiste no comando para o banco de dados no formato
``[COMANDO] [CHAVE] [VALOR]``, buscando primeiro as seguintes regras: 
  - `[COMANDO]` precisa ser um dos cinco descritos.
  - `[CHAVE]` precisa ser uma string.
  - `TRUE`, `FALSE` e números (exclusivamente, como `123`) sem estarem cercados de aspas não são strings, portanto, não podem ser chaves.
  - Se a chave ou valor contiverem espaços, precisam estar cercados de aspas.
  - Se uma aspa solta existir no meio de uma chave ou string, ela precisa ser precedida de um escape char. (Exemplo: `ab\"c` )

O servidor dispõe dos cinco comandos descritos: `GET`, `SET`, `BEGIN`, `ROLLBACK` e `COMMIT`.

### GET
`GET [CHAVE]` -> `Erro`

Primeiro checa se existe uma transação do usuário rolando.
Se existir, busca a chave nessa transação. Se não, busca a chave diretamente no banco de dados, retornando o valor se existir ou `NIL` se não.

### SET
`SET [CHAVE] [VALOR]` -> `VALOR_VELHO VALOR_NOVO` ou `Erro`

Se usuário tiver transação ativa, busca primeiro na própria pilha de transações pelo valor a ser alterado. Se não, busca o valor diretamente no banco, armazena o valor lido na transaçao como o valor antigo junto com o valor novo.
Se não existir transação ativa, busca direto no banco de dados.
Em ambos os casos, se a chave não existir, ela é criada e `NIL` é retornado como `VALOR_VELHO`

### BEGIN
`BEGIN` -> `OK` ou `Erro`

Não aceita outros parâmetros!
Caso o usuário não tenha uma transação ativa, começa uma nova.

### ROLLBACK
`ROLLBACK` -> `OK`ou `Erro`

Também não aceita parâmetros.
Se usuário estiver em transação, desfaz a transação do usuário.

### COMMIT
`COMMIT` -> `OK` ou `Erro`

Aplica as mudanças armazenadas de um usuário SOMENTE se os valores antigos armazenados na transação batem com os valores atuais do banco de dados. 

Exemplo: \
Chave ABC contém Valor 123 \
José começa uma transação \
José altera chave ABC para valor 456 \
Sofia altera chave ABC para valor 789 \
José tenta fazer o `COMMIT`, recebe erro de atomicidade pois o valor de quando ele leu a chave ABC pela primeira vez mudou desde então.


## Decisões relevantes tomadas
O banco de dados é o arquivo `priv/cumbuquinha.txt`. Acabei decidindo por separar chaves e valores com um `->` entre eles em cada linha!

Usei um Agent simples pra armazenar o estado de transações de cada usuário.

O parsing do comando enviado acabou virando um misto de regex com function clauses e cases e acredito que é a parte menos legível do código. Poderia provavelmente encontrar soluções melhores dado mais tempo!

Escrevi vários testes unitários e alguns de integração usando o ExUnit mesmo e consegui um bom coverage %.

# Cat Tax!!!

![a coisa mais linda do mundo](cat_tax.jpeg)
