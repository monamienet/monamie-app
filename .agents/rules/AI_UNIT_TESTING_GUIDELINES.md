# Diretrizes de Testes Unitários para Agentes de IA

Este documento define **o que** testar, **como** escrever o teste e **quanto** a suíte pode custar. Vale para todos os agentes de IA que atuam neste repositório.

O objetivo é uma suíte pequena, rápida e que quebre só quando o comportamento quebra. Um teste que falha porque alguém mudou um comentário no Gradle não protege nada; ele só custa tempo.

---

## 1. O que testar

Teste código que **toma decisões**:

- validação e conversão de dados (ex.: `OrganizationConfig.fromBranding`, leitura de documentos do Firestore);
- regras de derivação (ex.: id do parceiro a partir de `<id>NN@monamienet.org`, paleta a partir da cor primária, planos B da marca);
- controladores e serviços com ramificações (sucesso, erro, reentrância, timeout);
- regras de segurança (`firestore.rules`, nos testes de integração com emulador);
- **regressões**: todo bug corrigido ganha um teste que falharia sem a correção.

## 2. O que **não** testar

- **Arquivos de configuração lidos por regex** (Gradle, YAML de CI, `pubspec.yaml`, `.gitignore`, manifestos). Quem verifica a configuração é o próprio build e a CI.
- **Modelos sem lógica**: getters, construtores e `toMap`/`fromMap` campo a campo. Teste só a conversão que tem regra (valor padrão, tipo convertido, campo legado).
- **Comportamento do framework ou de plugins** (que o `Text` mostra o texto, que o `Hive` grava).
- **Funções auxiliares do próprio teste.**
- **Cópias da implementação**: se o teste recalcula o resultado com a mesma fórmula do código, ele não prova nada. Use valores fixos conhecidos.
- **Textos de interface**, a não ser que o texto seja a regra (ex.: a mensagem de "parceiro não encontrado").

Ao remover uma funcionalidade, remova os testes dela **no mesmo commit**.

## 3. Como escrever

### 3.1 Padrão AAA (Arrange, Act, Assert)

Todo teste tem as três seções, cada uma com seu comentário:

```dart
// 1. Arrange
...
// 2. Act
...
// 3. Assert
...
```

### 3.2 Um Act por teste

- O teste executa **uma** ação e verifica só o efeito dela.
- Preparações (ex.: serializar um objeto para testar a desserialização) ficam no Arrange.
- Variações de entrada viram testes separados. Para tabelas de casos, gere um `test()` por linha com um laço **fora** do `test()`; cada teste gerado continua com um único Act.

### 3.3 Tríade por unidade

Cada **unidade com lógica** (não cada função trivial) cobre:

| Cenário | Exemplo |
| :--- | :--- |
| **Happy Path** | documento de marca completo vira a marca do parceiro |
| **Edge Case** | campo opcional ausente cai no plano B |
| **Sad Path** | cor malformada é tratada como ausente; JSON com tipo errado lança `FormatException` |

### 3.4 Organização

- Um arquivo de teste por unidade, espelhando `lib/` (`lib/app/x/y.dart` → `test/unit/.../y_test.dart`).
- Prefira testar funções puras. Use widget tests só quando a decisão está no widget.
- Dependências externas (Firebase, HTTP, plugins) entram por contrato e são trocadas por *fakes* no teste.

## 4. Orçamento

- `flutter test test/unit -j 2` deve terminar em **menos de 2 minutos** num notebook com 8 GB de RAM.
- Se a suíte passar disso, corte primeiro os testes da seção 2 antes de adicionar novos.
- Rode sempre com concorrência baixa (`-j 2`) e prioridade baixa (`nice`) quando a máquina estiver em uso.

## 5. Independência

Os testes de **lógica nova ou alterada** são escritos por um agente de IA com **janela de contexto independente** da que implementou a mudança. Um agente com contexto limpo testa o contrato público, sem herdar os pressupostos (e os erros) da implementação.

## 6. Checklist

- [ ] Só testa código que toma decisões (seção 1) e nada da seção 2?
- [ ] Cada teste tem `// 1. Arrange`, `// 2. Act`, `// 3. Assert` e um único Act?
- [ ] Cada unidade com lógica cobre Happy Path, Edge Case e Sad Path?
- [ ] Os testes de lógica nova foram escritos por um agente com contexto independente?
- [ ] `flutter test test/unit -j 2` passou com código 0 dentro do orçamento?
