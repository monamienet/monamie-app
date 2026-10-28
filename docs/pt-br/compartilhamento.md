# Compartilhamento de localização: nomes e mecanismo

Este documento registra os nomes que usamos para falar do compartilhamento de localização e explica, com
esses nomes, como o app decide quem aparece no mapa. Ele serve de referência para conversas, issues,
revisões e código.

> **Resumo para explicar a alguém:** quem compartilha tem um interruptor (**isTracked**) e um carimbo de
> hora (**timestamp**). O aparelho renova o carimbo quando grava uma posição nova e a cada **heartbeat**,
> mesmo com a pessoa parada. Quem observa vê a pessoa enquanto o interruptor estiver ligado e o carimbo
> tiver menos que a **validade** (12 minutos). Como um aparelho morto não grava mais nada, o mapa
> confere de novo a cada **recheck** (30 segundos) para notar o silêncio.

---

## 1. Os nomes

| Nome | O que é | Quem define | Valor | No código | No Firestore |
|---|---|---|---|---|---|
| **período mínimo** | o menor tempo permitido entre duas posições gravadas | MonAmieNet, pelo plano | Community: 15 min; Standard: nenhum | `minPeriodMinutes`, `_minPeriod` | `config/plan.minIntervalMinutes` |
| **período** | o tempo que o responsável pede entre duas posições; nunca menor que o **período mínimo** | responsável, em *Ajustes de acompanhamento* | 1 a 30 min | `periodMinutes` | `config/tracking.intervalMinutes` |
| **raio** | quanto a pessoa precisa se afastar da última posição gravada para gravar outra | responsável | 5 a 500 m | `radiusMeters` | `config/tracking.distanceMeters` |
| **timestamp** | quando o aparelho de quem compartilha atualizou o documento dele pela última vez | o aparelho | data e hora | `timestamp` | `usuarios/{email}.timestamp` |
| **idade** | quanto tempo passou desde o **timestamp** | calculada por quem observa | agora − **timestamp** | `now.difference(timestamp)` | — |
| **isTracked** | se a pessoa quer compartilhar | a própria pessoa, pelo botão | ligado ou desligado | `isTracked` | `usuarios/{email}.isTracked` |
| **heartbeat** | a renovação do **timestamp** sem gravar posição nova, repetida a intervalo constante | código | a cada 5 min | `heartbeat` | — |
| **validade** | por quanto tempo um **timestamp** mantém a pessoa no mapa | código | 12 min | `validity` | — |
| **recheck** | a repetição da conferência do mapa sem nenhuma mudança no Firestore | código | a cada 30 s | `recheck` | — |

Os três valores fixos ficam em [`sharing_times.dart`](../../lib/app/data/tracking/sharing_times.dart).
Os campos do Firestore mantêm os nomes antigos para não exigir migração dos dados de nenhum parceiro.

Na tela de *Ajustes*, o **período** também aparece como frequência ("até 4 posições por hora"). É só outra
forma de mostrar o mesmo número: a frequência é o inverso do **período**.

## 2. O caminho de uma posição

Quem compartilha tem, no próprio aparelho, um serviço em segundo plano (um *isolate*, uma parte do app que
roda separada da tela). Ele faz duas coisas:

1. **Grava posições.** O GPS entrega um ponto mais ou menos a cada **período**. O serviço só grava se a
   pessoa saiu do **raio** em volta da última posição gravada e, no Community, se já passou o **período
   mínimo** desde a última posição gravada. As regras do Firestore conferem o **período mínimo** de novo,
   com o relógio do servidor, então um app modificado não consegue burlar o plano.
2. **Bate o heartbeat.** A cada **heartbeat**, ele renova só o **timestamp**, sem tocar na posição. Por não
   mudar a posição, o **heartbeat** não esbarra no **período mínimo**.

Uma posição nova também renova o **timestamp**. Por isso, enquanto o aparelho está vivo e conectado, a
**idade** nunca passa de um **heartbeat** (5 minutos), esteja a pessoa andando ou parada.

A volta não vale. **Idade** pequena não prova que o aparelho está vivo: um aparelho que morreu há um minuto
ainda tem **idade** de um minuto. E **idade** grande não prova que morreu: ele pode estar vivo e sem
internet.

## 3. Quem aparece no mapa

O aparelho de quem observa recebe do Firestore os documentos da equipe selecionada e confere, pessoa por
pessoa:

> a pessoa aparece no mapa se o **isTracked** estiver ligado **e** a **idade** for menor que a **validade**.

Essa conferência roda em dois momentos:

- quando o Firestore avisa que algum documento da equipe mudou;
- a cada **recheck**, com os documentos que o aparelho já tem e o horário atual.

O **recheck** existe por causa do aparelho que morre. Bateria acabou ou o sistema fechou o app: ninguém
desliga o **isTracked**, e o **timestamp** para de ser renovado. Como o aparelho morto não atualiza o
documento dele no Firestore, nenhum aviso chega a quem observa. Sem o **recheck**, a conferência nunca seria
refeita e a pessoa ficaria no mapa para sempre. Com ele, o horário atual avança, a **idade** cresce, e a
pessoa sai do mapa quando passa da **validade**.

## 4. Como alguém deixa de compartilhar

| Como parou | Quem grava **isTracked** desligado | Quando some do mapa |
|---|---|---|
| Botão de compartilhamento | o próprio app, na hora | assim que o Firestore avisa quem observa |
| Logout, troca de organização, exclusão da conta | o próprio app, antes de sair | assim que o Firestore avisa quem observa |
| Aparelho morto (bateria, sistema, sem internet) | ninguém | até uma **validade** mais um **recheck** depois do último **timestamp** |

No último caso, o documento continua com **isTracked** ligado no Firestore. Só a tela de quem observa
esconde a pessoa.

O ponto "você está aqui", que cada pessoa vê de si mesma, não depende do Firestore: ele aparece só enquanto o
compartilhamento do próprio aparelho está ligado.

## 5. Por que a validade é 12 minutos

A **validade** precisa atender a duas exigências que puxam em direções opostas:

- **ser maior que o heartbeat, com folga.** Uma pessoa viva e parada só renova o **timestamp** pelo
  **heartbeat**. Se a **validade** fosse menor que 5 minutos, ela sumiria do mapa entre dois pulsos e
  voltaria no seguinte;
- **ser curta.** Quanto maior a **validade**, mais tempo um aparelho morto continua no mapa.

12 minutos tolera perder um **heartbeat** inteiro, por rede lenta ou porque o Android adiou o timer para
economizar bateria, e mais 2 minutos de folga. Um aparelho morto sai do mapa em até 12,5 minutos.

Antes, a **validade** era 2 vezes o **período**. Isso dava 30 minutos no Community, longo demais, e 2 minutos
no preset Precisão, menos que o **heartbeat**. A **validade** deixou de depender do **período** porque quem
limita a **idade** de um aparelho vivo é o **heartbeat**, não o **período**.

## 6. Exemplos

**Ana, preset Economia (período de 15 min, raio de 100 m), Community:**

- **08:00:** liga o compartilhamento; a primeira posição é gravada.
- **08:05:** está parada; o **heartbeat** renova o **timestamp**.
- **08:16:** andou 2 km; o GPS entrega um ponto, já passou o **período mínimo**, a posição é gravada.
- **08:18:** a bateria acaba. Último **timestamp**: 08:16.
- **08:28 (mais até 30 s):** a **idade** passa de 12 minutos; no **recheck** seguinte, a Ana sai do mapa.

**Bruno, parado numa portaria por uma hora:** nenhuma posição é gravada, porque ele não sai do **raio**. O
**heartbeat** renova o **timestamp** a cada 5 minutos, a **idade** nunca chega a 12, e o Bruno continua no
mapa a hora toda.

## 7. O que ainda não foi verificado

- **Pulsos com a tela desligada:** não foi medido se o **heartbeat** chega de 5 em 5 minutos com a tela do
  aparelho apagada por muito tempo. Se o Android adiar o timer por mais de 7 minutos, a pessoa some do mapa
  por engano até o pulso seguinte.
- **Relógios diferentes:** o **timestamp** é gravado com o relógio de quem compartilha, e a **idade** é
  calculada com o relógio de quem observa. Se os dois aparelhos discordarem por minutos, a pessoa sai antes
  ou depois do esperado.
- **Período igual ao período mínimo:** no Economia, o GPS entrega um ponto a cada cerca de 15 minutos, mas
  o serviço exige 15 minutos e 10 segundos. Um ponto que chegue alguns segundos antes é descartado, e as
  posições podem ficar 30 minutos separadas. O **heartbeat** mantém a pessoa no mapa nesse caso; o que
  piora é só o trajeto.
- **Recheck com a tela desligada:** não foi verificado se o **recheck** roda com a tela de quem observa
  desligada. Ao voltar, a conferência é refeita em até 30 segundos.
