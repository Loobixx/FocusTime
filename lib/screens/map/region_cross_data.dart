class RegionCross {
  final String id;
  final String name;
  final double x;
  final double y;
  final double angle;
  final double size;
  
  // ✨ Les 3 nouvelles petites lignes pour l'image ✨
  final String? imagePath; 
  final double? imageX;
  final double? imageY;

  const RegionCross({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.angle = 0.0,
    this.size = 28.0,
    this.imagePath, // Le lien vers l'image (ex: 'assets/ville.png')
    this.imageX,    // La position X de l'image
    this.imageY,    // La position Y de l'image
  });
}

class RegionCrossesData {
  static const Map<String, List<RegionCross>> crossesByRegion = {
    'montagnes': [
      RegionCross(id:'m1', name: 'La tombe oubliée', x: 203.0, y: 1131.0, angle: 0.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m1.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m2', name: 'Le ponton des brunes', x: 368.0, y: 1050.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m2.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m3', name: 'Le Ruisseau des murmures', x: 628.0, y: 1091.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m3.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m4', name: 'La grange au vent', x: 426.0, y: 1213.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m4.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m5', name: 'Le campement de l\'île Sud', x: 455.0, y: 1423.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m5.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m6', name: 'Le phare d\'Orane', x: 585.0, y: 1322.0, angle: 30.0, size: 20.0, imagePath:'assets/NomCitiesMontagnes/m6.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m7', name: 'Le bosquet enchanté', x: 772.0, y: 1199.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m7.png', imageX: 0.0, imageY: 0.0),
      // A ne pas afficher RegionCross(id:'m8', name: 'Le plateau d\'Orane', x: 664.0, y: 105.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m8.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m9', name: 'L\'épée Maudite', x: 1264.0, y: 1166.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m9.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m10', name: 'L\'île Aos Sé', x: 1143.0, y: 1021.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m10.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m11', name:'Le village de Néris', x:788.0, y:966.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m11.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m12', name: 'L\'Halte blanche', x: 952.0, y: 770.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m12.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m13', name: 'Les nacelles du Pics', x: 1122.0, y: 560.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesMontagnes/m13.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'m14', name:'Le refuge des neiges', x:932.0, y:487.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m14.png', imageX:0.0, imageY:0.0),
      // A ne pas afficherRegionCross(id:'m15', name:'La chaine de montagnes d\'Orane', x:383.0, y:1156.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m15.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m16', name:'Le chateau d\'azur', x:732.0, y:376.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m16.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m17', name:'Le sommet d\'azur', x:660.0, y:187.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m17.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m18', name:'La stelle des montagnes d\'Orane', x:450.0, y:235.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m18.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m19', name:'L\'observatoire d\'Ouest', x:468.0, y:525.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m19.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m20', name:'L\'Antre d\'émeraude', x:758.0, y:638.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m20.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m21', name:'Le cercle des anciens', x:679.0, y:809.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m21.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m22', name:'Les ruines de garde-roc', x:552.0, y:985.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m22.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m23', name:'Le miroir d\'Emeraude', x:738.0, y:754.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m23.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'m24', name:'La forêt d\'Orane', x:216.0, y:919.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesMontagnes/m24.png', imageX:0.0, imageY:0.0),
    ],
    'desert': [
      RegionCross(id: 'd1', name: 'La port de commerce de Solaris', x: 435.0, y: 483.0, angle: 0.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d1.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd2', name: 'La cité Solaris', x: 561.0, y: 431.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d2.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd3', name: 'Le coeur du désert', x: 669.0, y: 705.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d3.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd4', name: 'La piste des marchands', x: 645.0, y: 820.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d4.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd5', name: 'Le bain du désert', x: 399.0, y: 1002.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d5.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd6', name: 'L\'autel du soleil', x: 540.0, y: 1001.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d6.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd7', name: 'Le cimetières des géants', x: 651.0, y: 1179.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d7.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd8', name: 'Le puits des Mirages', x: 664.0, y: 105.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d8.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd9', name: 'Le piège des sables', x: 776.0, y: 427.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d9.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd10', name: 'La stelle du desert de Sahur', x: 824.0, y: 500.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d10.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd11', name: 'Le champs des épines', x: 914.0, y: 713.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d11.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd12', name: 'La porte du désert', x: 917.0, y: 779.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d12.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id: 'd13', name: 'Les monts de Sahur', x: 758.0, y: 927.0, angle: 30.0, size: 20.0, imagePath: 'assets/NomCitiesDesert/d13.png', imageX: 0.0, imageY: 0.0),
      RegionCross(id:'d14', name:'Le passage secret', x:317.0, y:1540.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesDesert/d14.png', imageX:0.0,imageY:0.0),
      RegionCross(id:'d15', name:'La grotte infini', x:383.0, y:1156.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesDesert/d15.png', imageX:0.0, imageY:0.0),
      RegionCross(id:'d16', name:'L\'oasis de l\'exil', x:194.0, y:1497.0, angle:30.0, size:20.0, imagePath:'assets/NomCitiesDesert/d16.png', imageX:0.0, imageY:0.0),
    ],
    'lac': [
      RegionCross(id: 'l1', name: 'Rive Calme', x: 400.0, y: 600.0, angle: 10.0, size: 28.0),
    ],
    'nuit': [
      RegionCross(id: 'n1', name: 'Sanctuaire Obscur', x: 500.0, y: 700.0, angle: 60.0, size: 28.0),
    ],
    'nuages': [
      RegionCross(id: 'u1', name: 'Île Céleste', x: 550.0, y: 650.0, angle: 20.0, size: 28.0),
    ],
  };
}