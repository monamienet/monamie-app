# Diretrizes de Testes Unitários para Agentes de IA

Este documento estabelece o padrão obrigatório para a criação, reformulação e manutenção de testes unitários em toda a base de código. Todos os agentes de inteligência artificial que atuam neste repositório devem seguir rigorosamente os princípios aqui definidos.

---

## 1. Princípio da Separação de Contexto (Agente Independente)

> **Regra Fundamental**: Para cada tarefa ou implementação realizada no projeto, testes unitários **sempre deverão ser gerados**.
>
> **Obrigatório**: Os testes unitários **devem ser criados por um agente de IA com uma janela de contexto independente** daquele que realizou a tarefa.

### Racional:
- **Prevenção de Viés de Confirmação**: O agente que escreveu a implementação tende a reproduzir nos testes os mesmos pressupostos, atalhos e eventuais falhas lógicas do código-fonte.
- **Validação de Especificação e Contrato**: Um agente com contexto limpo examina a interface pública, contratos esperados, restrições e requisitos sem vícios de contexto prévio, garantindo testes robustos e fidedignos.

---

## 2. O Padrão AAA (Arrange, Act, Assert)

Todo e qualquer teste unitário deve ser estruturado em exatamente **3 seções explícitas**:

1. **Arrange**: Preparação do estado, dados de entrada, mocks, stubs e pré-condições.
2. **Act**: Execução da unidade, método ou função sendo testada.
3. **Assert**: Verificação das saídas, estados alterados ou exceções geradas.

### Comentários de Seção Obrigatórios
Antes de cada seção propriamente dita, **deve existir um comentário** indicando de qual seção se trata:
```dart
// 1. Arrange
...
// 2. Act
...
// 3. Assert
...
```

---

## 3. Regra do Ato Único (Single Act) e Assert Específico

- **Apenas 1 (um) Act por teste**: É estritamente proibido encadear múltiplos atos no mesmo teste (e.g., executar ação A, fazer assert, executar ação B, fazer assert).
- **Assert focado no resultado do Act**: O bloco `// 3. Assert` deve validar exclusivamente o resultado direto ou os efeitos colaterais da ação disparada no `// 2. Act`.
- **Preparações pertencem ao Arrange**: Se um teste precisa de um objeto resultante de outra operação (como um modelo serializado para testar desserialização), essa operação preliminar deve ocorrer no `// 1. Arrange`.
- **Cenários múltiplos devem ser divididos**: Se você deseja testar variações de entrada (ex: valor nulo vs. mapa vazio), divida em testes separados. Nunca utilize laços (`for`/`while`) disparando múltiplos atos dentro de um mesmo caso de teste.

---

## 4. Cobertura da Tríade de Cenários

O conjunto de testes unitários de cada unidade funcional deve cobrir obrigatoriamente:

| Cenário | Descrição | Exemplos |
| :--- | :--- | :--- |
| **Happy Path** *(Caminho Feliz)* | Execução sob condições normais com dados de entrada válidos e esperados. | Model inicializado com parâmetros válidos; autenticação autorizada retornando grupos permitidos. |
| **Edge Case** *(Casos Limite)* | Entradas nos limites de tolerância, coleções vazias, valores zero, strings em branco, normalizações de maiúsculas/espaços ou parâmetros opcionais nulos. | Mapa de claims vazio `{}`; strings com espaços periféricos e letras maiúsculas; ausência de chave opcional mantendo integridade. |
| **Sad Path** *(Caminho Infeliz / Erro)* | Comportamento diante de falhas esperadas, permissão negada, entradas malformadas, tipos incompatíveis ou dados corrompidos. | Tentativa de ação sem permissão resultando em bloqueio/retorno nulo; passagem de tipos inválidos gerando `TypeError` ou exceção customizada. |

---

## 5. Exemplo Canônico de Referência

Abaixo está o modelo ideal que deve ser seguido por qualquer agente ao redigir testes:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExemploController / Model - Suíte de Testes Unitários', () {
    test('Happy Path: Deve calcular total de itens com sucesso para entrada válida', () {
      // 1. Arrange
      final itemPrecos = [10.0, 20.0, 30.0];
      final calculadora = CalculadoraFinanceira();

      // 2. Act
      final total = calculadora.somar(itemPrecos);

      // 3. Assert
      expect(total, 60.0);
    });

    test('Edge Case: Deve retornar zero quando a lista de itens estiver vazia', () {
      // 1. Arrange
      final itensVazios = <double>[];
      final calculadora = CalculadoraFinanceira();

      // 2. Act
      final total = calculadora.somar(itensVazios);

      // 3. Assert
      expect(total, 0.0);
    });

    test('Sad Path: Deve lançar ArgumentError quando encontrar preço negativo', () {
      // 1. Arrange
      final itensComValorNegativo = [10.0, -5.0, 20.0];
      final calculadora = CalculadoraFinanceira();

      // 2. Act
      action() => calculadora.somar(itensComValorNegativo);

      // 3. Assert
      expect(action, throwsA(isA<ArgumentError>()));
    });
  });
}
```

---

## 6. Checklist de Verificação para o Agente de Testes

Antes de finalizar qualquer tarefa de teste, valide:

- [ ] Os testes foram criados por um agente com contexto independente?
- [ ] Todos os testes possuem as 3 seções comentadas (`// 1. Arrange`, `// 2. Act`, `// 3. Assert`)?
- [ ] Cada teste possui exatamente **um** Act?
- [ ] Os asserts validam única e especificamente o resultado daquele Act?
- [ ] O conjunto de testes contempla **Happy Path**, **Edge Case** e **Sad Path**?
- [ ] O comando `flutter test` foi executado e todos os testes passaram com código 0?
