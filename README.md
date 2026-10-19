# 🌾 Monitoramento de Pragas com Integração QGIS

Aplicativo Flutter desenvolvido seguindo as melhores práticas de arquitetura de software (Clean Architecture, SOLID, Riverpod e SQLite Offline-First) para registro georreferenciado de pragas agrícolas e exportação direta para **QGIS**, **Google Earth** e outros Sistemas de Informação Geográfica (SIG).

---

## 🚀 Funcionalidades Principais

1. **Registro Georreferenciado Completo**:
   - **Identificação da Praga**: Lista de pragas agrícolas comuns (*Spodoptera*, *Helicoverpa*, *Percevejo-marrom*, *Mosca-branca*, *Bicudo*, etc.) + opção de praga personalizada.
   - **Contagem Rápida de Insetos**: Campo numérico com botões de incremento rápido (+1, +5, +10, +20, +50) para agilizar o trabalho no campo.
   - **Localização GPS de Alta Precisão**: Captura automática de Latitude, Longitude, Altitude e Precisão em metros (WGS 84 / EPSG:4326), com opção de ajuste manual no mapa.
   - **Contexto Agronômico**: Cultura (*Soja, Milho, Algodão, Café, etc.*), Talhão/Pivô, Estágio de Desenvolvimento e Observações de Campo.

2. **Visualização Espacial no App**:
   - **Mapa Interativo (OpenStreetMap)** com círculos de tamanho e cor proporcionais à quantidade de pragas coletadas em cada ponto.
   - **Dashboard Estatístico**: Total de pragas, média por ponto, ponto de infestação máxima e praga predominante.
   - **Filtros Avançados**: Filtre por praga, talhão, cultura, período de datas e nível mínimo de infestação.

3. **Exportação Especializada para QGIS & SIGs**:
   - **GeoJSON RFC 7946 (.geojson)**: Formato ideal para arrastar e soltar diretamente no QGIS. Contém atributos numéricos para estilização graduada imediata.
   - **Pacote QGIS (.geojson + .qml)**: Exporta o GeoJSON junto com um arquivo de estilo `.qml` pronto para carregar no QGIS com círculos graduados por quantidade e rótulos automáticos!
   - **Tabela CSV com WKT (.csv)**: Colunas `latitude`, `longitude` e `wkt_geom` (`POINT(lng lat)`).
   - **Google Earth KML (.kml)**: Visualização em 3D com marcadores coloridos por severidade e balões informativos.
   - **Compartilhamento Direto**: Envio via WhatsApp, Google Drive, E-mail, Bluetooth ou salvamento local.

---

## 🗺️ Como Abrir e Estilizar os Dados no QGIS

### Opção A: Arrastando o Arquivo GeoJSON (Mais Rápido)
1. Abra o **QGIS**.
2. Arraste o arquivo `.geojson` exportado para a área de trabalho do QGIS.
3. Se você exportou o **Pacote QGIS**, clique com o botão direito na camada -> **Propriedades** -> **Estilo** (no rodapé) -> **Carregar Estilo...** e selecione o arquivo `.qml`. Pronto! Os círculos proporcionais e rótulos serão aplicados automaticamente.

### Opção B: Configuração Manual de Círculos Proporcionais por Quantidade
1. Clique duas vezes na camada no painel de camadas para abrir as **Propriedades**.
2. Vá na aba **Simbologia** e mude de *Símbolo Simples* para **Graduado**.
3. No campo **Valor**, selecione `quantidade`.
4. Em **Método**, escolha **Tamanho** (para círculos maiores onde há mais pragas) ou **Cor** (gradiente do verde ao vermelho).
5. Clique em **Classificar** e depois em **OK**.

### Opção C: Exibição de Rótulos (Nome e Quantidade no Ponto)
1. Nas **Propriedades da Camada**, vá na aba **Rótulos (Labels)**.
2. Selecione **Rótulos Individuais (Single Labels)**.
3. No campo **Valor**, selecione `quantidade` ou use a expressão:
   ```sql
   "praga" || ' (' || "quantidade" || ' un)'
   ```
4. Ative a opção **Buffer de Texto** (cor branca) para facilitar a leitura no mapa.

### Opção D: Mapa de Calor (Heatmap de Infestação)
1. Nas **Propriedades da Camada**, aba **Simbologia**, selecione o renderizador **Mapa de Calor (Heatmap)**.
2. No campo **Ponderar por (Weight by)**, selecione a coluna `quantidade`.
3. Ajuste o **Raio** para cerca de 15 a 25 mm e selecione uma rampa de cores como *Reds* ou *Magma*.

---

## 🧱 Arquitetura do Projeto

```
lib/
├── main.dart                                  # Ponto de entrada com ProviderScope e Tema
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                   # Cores agronômicas e faixas de severidade
│   │   └── default_pests.dart                # Catálogo de pragas e culturas agrícolas
│   ├── database/
│   │   └── db_helper.dart                    # SQLite Local Database (Offline-First)
│   ├── services/
│   │   ├── location_service.dart             # Captura de GPS de alta precisão
│   │   └── export_service.dart               # Gerador de GeoJSON, CSV, KML e Estilo QML
│   ├── theme/
│   │   └── app_theme.dart                    # Tema Material 3 customizado
│   └── utils/
│       └── qgis_helper.dart                  # Guias e instruções passo a passo para QGIS
└── features/
    └── pest_records/
        ├── domain/
        │   ├── models/
        │   │   ├── pest_record.dart          # Modelo de domínio com mapeamento espacial
        │   │   └── pest_statistics.dart      # Cálculo de métricas e agregados
        │   └── repositories/
        │       └── pest_record_repository.dart
        ├── data/
        │   └── repositories/
        │       └── sqlite_pest_record_repository.dart
        └── presentation/
            ├── providers/
            │   ├── pest_records_provider.dart # Gerenciamento de estado (Riverpod)
            │   └── location_provider.dart     # Provedor do estado do GPS
            ├── screens/
            │   ├── home_screen.dart           # Lista com estatísticas, busca e filtros
            │   ├── add_edit_record_screen.dart# Formulário com GPS e mapa de ajuste
            │   ├── record_detail_screen.dart  # Detalhes, coordenadas e WKT
            │   ├── map_view_screen.dart       # Mapa de infestação com círculos graduados
            │   └── export_screen.dart         # Exportador multiformato e tutorial
            └── widgets/
                ├── pest_card.dart             # Card do ponto com badge de severidade
                ├── stats_overview_card.dart   # Card com resumo estatístico
                ├── location_badge.dart        # Badge de status e precisão do GPS
                └── filter_bottom_sheet.dart   # Filtros por data, talhão e quantidade
```

---

## 🧪 Como Executar

1. **Instalar dependências**:
   ```bash
   flutter pub get
   ```

2. **Configurar variáveis de ambiente (`.env`)**:
   O projeto utiliza o arquivo `.env` para parametrizar a URL da API backend, o servidor de tiles do mapa, limites de GPS e banco de dados SQLite.
   Copie o modelo caso ainda não tenha o `.env`:
   ```bash
   cp .env.example .env
   ```
   Edite `.env` conforme necessário (ex.: IP do backend ou emulador Android `http://10.0.2.2:3000/api/v1`).

3. **Rodar os testes unitários**:
   ```bash
   flutter test
   ```

4. **Executar o aplicativo**:
   ```bash
   flutter run
   ```

---

## 🌐 API Backend (Node.js + TypeScript + PostgreSQL/PostGIS)

A API RESTful está localizada no diretório dedicado [`/home/takayuki/dev/backend-app-renata`](file:///home/takayuki/dev/backend-app-renata/README.md) com:
- **Autenticação Segura**: JWT + Refresh Tokens e senhas criptografadas com Bcrypt (salt 12).
- **Banco de Dados Geoespacial**: PostgreSQL 16 com extensão PostGIS para consultas espaciais e conexão direta com o QGIS.
- **Sincronização Offline-First**: Endpoint de sincronização em lote (`POST /api/v1/pest-records/sync`) compatível com o SQLite local do app Flutter.
- **Exportação Multiformato**: GeoJSON RFC 7946 e CSV com WKT POINT direto da nuvem.
- **Documentação Interativa**: Swagger UI em `/api/v1/docs`.

Para instruções de execução do backend, consulte o [README da API](file:///home/takayuki/dev/backend-app-renata/README.md).


