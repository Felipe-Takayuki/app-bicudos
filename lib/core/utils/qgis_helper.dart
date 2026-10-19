class QgisGuideStep {
  final String title;
  final String description;
  final String icon;

  const QgisGuideStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class QgisHelper {
  static const List<QgisGuideStep> geoJsonGuide = [
    QgisGuideStep(
      title: '1. Importar no QGIS',
      description: 'Abra o QGIS e simplesmente arraste o arquivo .geojson para a tela ou vá em Camada -> Adicionar Camada -> Adicionar Camada Vetorial.',
      icon: 'file_download',
    ),
    QgisGuideStep(
      title: '2. Configurar Rótulos (Nome e Quantidade)',
      description: 'Clique duas vezes na camada -> Aba Rótulos (Labels) -> Rótulo Simples. No campo Valor escolha "quantidade" ou monte a expressão: "praga" || \' (\' || "quantidade" || \')\'.',
      icon: 'label',
    ),
    QgisGuideStep(
      title: '3. Simbologia Graduada (Círculos Proporcionais)',
      description: 'Aba Simbologia -> Mude de "Símbolo Simples" para "Graduado". Em "Valor" selecione "quantidade". Escolha o Método "Tamanho" ou "Cor" (gradiente verde-amarelo-vermelho) e clique em "Classificar".',
      icon: 'bubble_chart',
    ),
    QgisGuideStep(
      title: '4. Mapa de Calor (Heatmap de Infestação)',
      description: 'Na Simbologia, selecione "Mapa de Calor" e no campo "Ponderar por" selecione "quantidade" com raio de 10 a 20 mm. Isso gerará uma mancha contínua de calor indicando focos!',
      icon: 'whatshot',
    ),
    QgisGuideStep(
      title: '5. Usando o arquivo .qml de Estilo',
      description: 'Se exportou o Pacote QGIS, clique com o botão direito na camada -> Propriedades -> Estilo (no rodapé) -> Carregar Estilo e selecione o arquivo .qml exportado pelo app!',
      icon: 'auto_fix_high',
    ),
  ];

  static const List<QgisGuideStep> csvGuide = [
    QgisGuideStep(
      title: '1. Adicionar Camada de Texto Delimitado',
      description: 'No menu superior: Camada -> Adicionar Camada -> Adicionar Camada de Texto Delimitado.',
      icon: 'table_chart',
    ),
    QgisGuideStep(
      title: '2. Definir Geometria de Ponto',
      description: 'Em Definição de Geometria, marque "Coordenadas de Ponto": Campo X = longitude, Campo Y = latitude. SRC da Geometria: EPSG:4326 - WGS 84.',
      icon: 'place',
    ),
    QgisGuideStep(
      title: '3. Visualizar Tabela e Estilizar',
      description: 'Clique em Adicionar. A tabela de atributos conterá quantidade, praga, cultura, talhão e data para filtros e mapas temáticos.',
      icon: 'visibility',
    ),
  ];
}
