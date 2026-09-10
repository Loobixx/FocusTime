import 'package:flutter/material.dart';

class RegionShape {
  final String id;
  final String name;
  final Color color;
  final Path path;

  RegionShape({
    required this.id,
    required this.name,
    required this.color,
    required this.path,
  });
}

class MapRegionsData {
  static final List<RegionShape> regions = [
RegionShape(
      id: 'desert',
      name: 'Terres du Désert',
      color: const Color(0xFFE8C468),
      path: () {
        final p = Path();
        
        // 1. Contour principal du désert
        p.moveTo(318, 320);
        p.lineTo(315, 336);
        p.lineTo(306, 353);
        p.lineTo(297, 365);
        p.lineTo(301, 372);
        p.lineTo(318, 377);
        p.lineTo(330, 384);
        p.lineTo(333, 400);
        p.lineTo(336, 411);
        p.lineTo(338, 420);
        p.lineTo(332, 429);
        p.lineTo(323, 440);
        p.lineTo(322, 455);
        p.lineTo(326, 462);
        p.lineTo(342, 465);
        p.lineTo(364, 463);
        p.lineTo(371, 463);
        p.lineTo(379, 471);
        p.lineTo(388, 476);
        p.lineTo(391, 489);
        p.lineTo(391, 504);
        p.lineTo(400, 520);
        p.lineTo(410, 535);
        p.lineTo(414, 552);
        p.lineTo(413, 564);
        p.lineTo(413, 581);
        p.lineTo(414, 599);
        p.lineTo(422, 612);
        p.lineTo(421, 624);
        p.lineTo(412, 637);
        p.lineTo(407, 650);
        p.lineTo(411, 665);
        p.lineTo(402, 682);
        p.lineTo(391, 686);
        p.lineTo(378, 688);
        p.lineTo(366, 698);
        p.lineTo(353, 711);
        p.lineTo(346, 732);
        p.lineTo(342, 743);
        p.lineTo(332, 755);
        p.lineTo(321, 764);
        p.lineTo(313, 778);
        p.lineTo(312, 794);
        p.lineTo(304, 810);
        p.lineTo(286, 820);
        p.lineTo(277, 816);
        p.lineTo(269, 811);
        p.lineTo(258, 811);
        p.lineTo(245, 802);
        p.lineTo(233, 795);
        p.lineTo(220, 795);
        p.lineTo(209, 799);
        p.lineTo(200, 809);
        p.lineTo(190, 811);
        p.lineTo(177, 809);
        p.lineTo(156, 805);
        p.lineTo(159, 795);
        p.lineTo(166, 786);
        p.lineTo(156, 784);
        p.lineTo(153, 771);
        p.lineTo(156, 754);
        p.lineTo(159, 739);
        p.lineTo(163, 722);
        p.lineTo(166, 704);
        p.lineTo(166, 690);
        p.lineTo(158, 674);
        p.lineTo(161, 653);
        p.lineTo(166, 633);
        p.lineTo(153, 614);
        p.lineTo(147, 599);
        p.lineTo(152, 576);
        p.lineTo(161, 564);
        p.lineTo(163, 548);
        p.lineTo(160, 537);
        p.lineTo(160, 523);
        p.lineTo(167, 511);
        p.lineTo(172, 495);
        p.lineTo(177, 477);
        p.lineTo(172, 462);
        p.lineTo(177, 450);
        p.lineTo(185, 431);
        p.lineTo(186, 413);
        p.lineTo(197, 403);
        p.lineTo(211, 395);
        p.lineTo(217, 378);
        p.lineTo(234, 371);
        p.lineTo(253, 360);
        p.lineTo(270, 347);
        p.lineTo(287, 334);
        p.lineTo(300, 322);
        p.close();

        // 2. Tracé de la petite île rattachée
        p.moveTo(125, 894);
        p.lineTo(128, 899);
        p.lineTo(133, 906);
        p.lineTo(144, 917);
        p.lineTo(143, 923);
        p.lineTo(140, 930);
        p.lineTo(139, 937);
        p.lineTo(145, 945);
        p.lineTo(152, 950);
        p.lineTo(152, 958);
        p.lineTo(150, 967);
        p.lineTo(142, 973);
        p.lineTo(133, 970);
        p.lineTo(120, 968);
        p.lineTo(111, 973);
        p.lineTo(103, 982);
        p.lineTo(94, 980);
        p.lineTo(87, 968);
        p.lineTo(86, 957);
        p.lineTo(78, 947);
        p.lineTo(70, 939);
        p.lineTo(75, 929);
        p.lineTo(84, 917);
        p.lineTo(90, 902);
        p.lineTo(102, 902);
        p.lineTo(111, 902);
        p.lineTo(117, 897);
        p.close();

        return p;
      }(),
    ),
      
   RegionShape(
      id: 'lac',
      name: 'Monde de l\'Eau',
      color: const Color(0xFF3FA9C9),
      path: Path()
        ..moveTo(392, 685)
        ..lineTo(380, 687)
        ..lineTo(364, 696)
        ..lineTo(355, 707)
        ..lineTo(349, 720)
        ..lineTo(342, 734)
        ..lineTo(341, 745)
        ..lineTo(326, 757)
        ..lineTo(319, 767)
        ..lineTo(311, 781)
        ..lineTo(310, 791)
        ..lineTo(315, 799)
        ..lineTo(309, 805)
        ..lineTo(300, 809)
        ..lineTo(295, 817)
        ..lineTo(283, 820)
        ..lineTo(273, 815)
        ..lineTo(269, 809)
        ..lineTo(260, 809)
        ..lineTo(251, 810)
        ..lineTo(244, 802)
        ..lineTo(236, 796)
        ..lineTo(221, 796)
        ..lineTo(206, 800)
        ..lineTo(202, 806)
        ..lineTo(198, 810)
        ..lineTo(185, 810)
        ..lineTo(170, 806)
        ..lineTo(159, 804)
        ..lineTo(154, 819)
        ..lineTo(161, 829)
        ..lineTo(164, 836)
        ..lineTo(163, 846)
        ..lineTo(159, 851)
        ..lineTo(160, 866)
        ..lineTo(162, 877)
        ..lineTo(169, 888)
        ..lineTo(177, 898)
        ..lineTo(190, 907)
        ..lineTo(194, 920)
        ..lineTo(192, 938)
        ..lineTo(191, 957)
        ..lineTo(187, 968)
        ..lineTo(183, 981)
        ..lineTo(177, 992)
        ..lineTo(175, 1006)
        ..lineTo(184, 1014)
        ..lineTo(185, 1022)
        ..lineTo(185, 1036)
        ..lineTo(183, 1043)
        ..lineTo(180, 1057)
        ..lineTo(182, 1064)
        ..lineTo(187, 1071)
        ..lineTo(191, 1080)
        ..lineTo(198, 1089)
        ..lineTo(195, 1099)
        ..lineTo(195, 1111)
        ..lineTo(202, 1115)
        ..lineTo(218, 1115)
        ..lineTo(234, 1119)
        ..lineTo(250, 1124)
        ..lineTo(261, 1128)
        ..lineTo(271, 1138)
        ..lineTo(280, 1146)
        ..lineTo(285, 1154)
        ..lineTo(289, 1139)
        ..lineTo(293, 1127)
        ..lineTo(305, 1116)
        ..lineTo(316, 1106)
        ..lineTo(325, 1097)
        ..lineTo(330, 1089)
        ..lineTo(335, 1081)
        ..lineTo(344, 1066)
        ..lineTo(358, 1054)
        ..lineTo(369, 1046)
        ..lineTo(375, 1026)
        ..lineTo(384, 1013)
        ..lineTo(394, 997)
        ..lineTo(403, 983)
        ..lineTo(406, 969)
        ..lineTo(413, 956)
        ..lineTo(420, 944)
        ..lineTo(423, 927)
        ..lineTo(422, 907)
        ..lineTo(426, 899)
        ..lineTo(431, 892)
        ..lineTo(436, 878)
        ..lineTo(438, 855)
        ..lineTo(435, 834)
        ..lineTo(430, 816)
        ..lineTo(428, 801)
        ..lineTo(430, 784)
        ..lineTo(425, 768)
        ..lineTo(419, 758)
        ..lineTo(413, 746)
        ..lineTo(407, 730)
        ..lineTo(397, 718)
        ..lineTo(392, 705)
        ..lineTo(392, 693)
        ..close(),
    ),
    RegionShape(
      id: 'nuit',
      name: 'Royaume de la Nuit',
      color: const Color(0xFF16215C),
      path: () {
        final p = Path();

        // 1. Continent principal de la nuit
        p.moveTo(425, 615);
        p.lineTo(422, 625);
        p.lineTo(414, 637);
        p.lineTo(407, 646);
        p.lineTo(411, 661);
        p.lineTo(407, 683);
        p.lineTo(393, 683);
        p.lineTo(392, 696);
        p.lineTo(391, 711);
        p.lineTo(399, 722);
        p.lineTo(410, 736);
        p.lineTo(430, 728);
        p.lineTo(452, 716);
        p.lineTo(465, 709);
        p.lineTo(477, 702);
        p.lineTo(484, 695);
        p.lineTo(492, 695);
        p.lineTo(500, 692);
        p.lineTo(501, 682);
        p.lineTo(511, 678);
        p.lineTo(522, 671);
        p.lineTo(533, 674);
        p.lineTo(543, 682);
        p.lineTo(550, 692);
        p.lineTo(551, 701);
        p.lineTo(555, 717);
        p.lineTo(562, 732);
        p.lineTo(570, 737);
        p.lineTo(585, 741);
        p.lineTo(595, 745);
        p.lineTo(605, 754);
        p.lineTo(613, 771);
        p.lineTo(620, 790);
        p.lineTo(626, 800);
        p.lineTo(631, 809);
        p.lineTo(640, 819);
        p.lineTo(654, 828);
        p.lineTo(670, 834);
        p.lineTo(689, 836);
        p.lineTo(700, 835);
        p.lineTo(718, 834);
        p.lineTo(730, 834);
        p.lineTo(743, 846);
        p.lineTo(753, 858);
        p.lineTo(763, 866);
        p.lineTo(770, 877);
        p.lineTo(780, 881);
        p.lineTo(790, 891);
        p.lineTo(805, 895);
        p.lineTo(820, 899);
        p.lineTo(839, 901);
        p.lineTo(859, 904);
        p.lineTo(868, 892);
        p.lineTo(874, 881);
        p.lineTo(877, 858);
        p.lineTo(871, 845);
        p.lineTo(866, 827);
        p.lineTo(864, 810);
        p.lineTo(867, 799);
        p.lineTo(873, 784);
        p.lineTo(881, 763);
        p.lineTo(887, 746);
        p.lineTo(890, 728);
        p.lineTo(891, 702);
        p.lineTo(889, 682);
        p.lineTo(882, 665);
        p.lineTo(865, 656);
        p.lineTo(847, 648);
        p.lineTo(830, 641);
        p.lineTo(822, 628);
        p.lineTo(817, 610);
        p.lineTo(813, 596);
        p.lineTo(801, 589);
        p.lineTo(790, 580);
        p.lineTo(779, 572);
        p.lineTo(771, 561);
        p.lineTo(758, 552);
        p.lineTo(749, 541);
        p.lineTo(728, 531);
        p.lineTo(717, 524);
        p.lineTo(705, 524);
        p.lineTo(705, 514);
        p.lineTo(694, 510);
        p.lineTo(683, 502);
        p.lineTo(667, 501);
        p.lineTo(650, 501);
        p.lineTo(635, 511);
        p.lineTo(625, 522);
        p.lineTo(614, 526);
        p.lineTo(601, 523);
        p.lineTo(590, 520);
        p.lineTo(576, 524);
        p.lineTo(568, 531);
        p.lineTo(564, 540);
        p.lineTo(555, 546);
        p.lineTo(552, 556);
        p.lineTo(550, 570);
        p.lineTo(542, 579);
        p.lineTo(536, 587);
        p.lineTo(535, 601);
        p.lineTo(525, 611);
        p.lineTo(515, 622);
        p.lineTo(513, 635);
        p.lineTo(510, 643);
        p.lineTo(500, 646);
        p.lineTo(490, 646);
        p.lineTo(487, 639);
        p.lineTo(490, 631);
        p.lineTo(489, 619);
        p.lineTo(483, 615);
        p.lineTo(476, 607);
        p.lineTo(467, 608);
        p.lineTo(462, 614);
        p.lineTo(455, 619);
        p.lineTo(445, 615);
        p.lineTo(437, 610);
        p.close();

        // 2. Île satellite de la nuit
        p.moveTo(830, 583);
        p.lineTo(839, 588);
        p.lineTo(839, 598);
        p.lineTo(854, 602);
        p.lineTo(855, 612);
        p.lineTo(864, 619);
        p.lineTo(872, 627);
        p.lineTo(880, 632);
        p.lineTo(890, 631);
        p.lineTo(900, 631);
        p.lineTo(907, 626);
        p.lineTo(908, 617);
        p.lineTo(905, 609);
        p.lineTo(908, 603);
        p.lineTo(905, 592);
        p.lineTo(903, 581);
        p.lineTo(898, 566);
        p.lineTo(900, 558);
        p.lineTo(900, 549);
        p.lineTo(894, 543);
        p.lineTo(893, 537);
        p.lineTo(890, 526);
        p.lineTo(882, 526);
        p.lineTo(870, 528);
        p.lineTo(862, 532);
        p.lineTo(857, 537);
        p.lineTo(849, 539);
        p.lineTo(835, 543);
        p.lineTo(831, 550);
        p.lineTo(828, 558);
        p.lineTo(828, 568);
        p.close();

        return p;
      }(),
    ),
    RegionShape(
      id: 'nuages',
      name: 'Les Nuages Féeriques',
      color: const Color(0xFFE79ACB),
      path: () {
        final p = Path();

        // 1. Continent principal des nuages
        p.moveTo(829, 278);
        p.lineTo(838, 279);
        p.lineTo(843, 283);
        p.lineTo(852, 288);
        p.lineTo(861, 281);
        p.lineTo(868, 273);
        p.lineTo(875, 270);
        p.lineTo(883, 266);
        p.lineTo(899, 269);
        p.lineTo(903, 277);
        p.lineTo(906, 283);
        p.lineTo(910, 290);
        p.lineTo(905, 298);
        p.lineTo(894, 306);
        p.lineTo(888, 314);
        p.lineTo(881, 321);
        p.lineTo(869, 323);
        p.lineTo(863, 329);
        p.lineTo(863, 342);
        p.lineTo(864, 355);
        p.lineTo(858, 362);
        p.lineTo(850, 372);
        p.lineTo(846, 380);
        p.lineTo(841, 391);
        p.lineTo(845, 400);
        p.lineTo(843, 408);
        p.lineTo(829, 416);
        p.lineTo(835, 429);
        p.lineTo(840, 442);
        p.lineTo(841, 459);
        p.lineTo(838, 470);
        p.lineTo(830, 479);
        p.lineTo(819, 488);
        p.lineTo(803, 483);
        p.lineTo(789, 485);
        p.lineTo(776, 483);
        p.lineTo(761, 488);
        p.lineTo(754, 484);
        p.lineTo(755, 477);
        p.lineTo(735, 483);
        p.lineTo(723, 489);
        p.lineTo(715, 481);
        p.lineTo(717, 473);
        p.lineTo(711, 471);
        p.lineTo(698, 472);
        p.lineTo(687, 466);
        p.lineTo(676, 458);
        p.lineTo(659, 455);
        p.lineTo(647, 448);
        p.lineTo(643, 433);
        p.lineTo(646, 428);
        p.lineTo(640, 423);
        p.lineTo(633, 424);
        p.lineTo(622, 422);
        p.lineTo(614, 413);
        p.lineTo(605, 407);
        p.lineTo(593, 407);
        p.lineTo(582, 401);
        p.lineTo(575, 393);
        p.lineTo(574, 381);
        p.lineTo(570, 374);
        p.lineTo(564, 375);
        p.lineTo(560, 368);
        p.lineTo(567, 361);
        p.lineTo(570, 352);
        p.lineTo(586, 343);
        p.lineTo(588, 333);
        p.lineTo(585, 323);
        p.lineTo(594, 311);
        p.lineTo(605, 303);
        p.lineTo(610, 290);
        p.lineTo(620, 290);
        p.lineTo(629, 294);
        p.lineTo(641, 294);
        p.lineTo(657, 293);
        p.lineTo(665, 297);
        p.lineTo(665, 303);
        p.lineTo(674, 303);
        p.lineTo(681, 298);
        p.lineTo(690, 298);
        p.lineTo(705, 295);
        p.lineTo(715, 291);
        p.lineTo(730, 286);
        p.lineTo(741, 286);
        p.lineTo(752, 285);
        p.lineTo(759, 288);
        p.lineTo(772, 284);
        p.lineTo(781, 281);
        p.lineTo(788, 270);
        p.lineTo(800, 268);
        p.lineTo(810, 265);
        p.lineTo(821, 266);
        p.close();

        // 2. Îlot 1
        p.moveTo(607, 240);
        p.lineTo(615, 248);
        p.lineTo(623, 251);
        p.lineTo(628, 256);
        p.lineTo(631, 263);
        p.lineTo(626, 267);
        p.lineTo(615, 270);
        p.lineTo(603, 270);
        p.lineTo(593, 267);
        p.lineTo(583, 263);
        p.lineTo(584, 256);
        p.lineTo(590, 252);
        p.lineTo(596, 253);
        p.lineTo(596, 246);
        p.close();

        // 3. Îlot 2
        p.moveTo(623, 228);
        p.lineTo(632, 232);
        p.lineTo(642, 230);
        p.lineTo(650, 237);
        p.lineTo(658, 239);
        p.lineTo(665, 242);
        p.lineTo(675, 243);
        p.lineTo(685, 242);
        p.lineTo(690, 236);
        p.lineTo(701, 242);
        p.lineTo(720, 245);
        p.lineTo(729, 238);
        p.lineTo(734, 233);
        p.lineTo(740, 233);
        p.lineTo(748, 231);
        p.lineTo(751, 223);
        p.lineTo(760, 223);
        p.lineTo(767, 223);
        p.lineTo(772, 220);
        p.lineTo(778, 220);
        p.lineTo(785, 216);
        p.lineTo(783, 206);
        p.lineTo(777, 205);
        p.lineTo(771, 201);
        p.lineTo(765, 199);
        p.lineTo(756, 193);
        p.lineTo(750, 183);
        p.lineTo(743, 180);
        p.lineTo(734, 176);
        p.lineTo(728, 175);
        p.lineTo(721, 167);
        p.lineTo(717, 159);
        p.lineTo(709, 158);
        p.lineTo(705, 151);
        p.lineTo(691, 148);
        p.lineTo(680, 149);
        p.lineTo(671, 159);
        p.lineTo(664, 158);
        p.lineTo(657, 160);
        p.lineTo(654, 168);
        p.lineTo(645, 168);
        p.lineTo(639, 171);
        p.lineTo(634, 176);
        p.lineTo(627, 177);
        p.lineTo(618, 181);
        p.lineTo(610, 194);
        p.lineTo(615, 203);
        p.lineTo(622, 208);
        p.lineTo(618, 218);
        p.close();

        // 4. Îlot 3
        p.moveTo(730, 262);
        p.lineTo(735, 259);
        p.lineTo(741, 253);
        p.lineTo(748, 254);
        p.lineTo(750, 262);
        p.lineTo(755, 266);
        p.lineTo(743, 270);
        p.lineTo(735, 267);
        p.close();

        // 5. Îlot 4
        p.moveTo(791, 110);
        p.lineTo(798, 116);
        p.lineTo(806, 121);
        p.lineTo(818, 121);
        p.lineTo(828, 116);
        p.lineTo(830, 111);
        p.lineTo(838, 111);
        p.lineTo(845, 106);
        p.lineTo(852, 103);
        p.lineTo(858, 97);
        p.lineTo(865, 91);
        p.lineTo(863, 82);
        p.lineTo(853, 80);
        p.lineTo(849, 75);
        p.lineTo(845, 72);
        p.lineTo(839, 69);
        p.lineTo(830, 69);
        p.lineTo(823, 66);
        p.lineTo(818, 70);
        p.lineTo(808, 66);
        p.lineTo(800, 68);
        p.lineTo(795, 72);
        p.lineTo(784, 76);
        p.lineTo(774, 79);
        p.lineTo(765, 82);
        p.lineTo(767, 89);
        p.lineTo(760, 96);
        p.lineTo(770, 105);
        p.lineTo(775, 110);
        p.lineTo(783, 111);
        p.close();

        // 6. Îlot 5
        p.moveTo(843, 156);
        p.lineTo(851, 161);
        p.lineTo(850, 161);
        p.lineTo(851, 161);
        p.lineTo(846, 170);
        p.lineTo(839, 167);
        p.lineTo(835, 161);
        p.close();

        // 7. Îlot 6
        p.moveTo(830, 226);
        p.lineTo(837, 223);
        p.lineTo(840, 216);
        p.lineTo(848, 217);
        p.lineTo(851, 209);
        p.lineTo(860, 203);
        p.lineTo(863, 194);
        p.lineTo(874, 194);
        p.lineTo(879, 186);
        p.lineTo(891, 184);
        p.lineTo(899, 188);
        p.lineTo(905, 183);
        p.lineTo(916, 181);
        p.lineTo(927, 186);
        p.lineTo(939, 190);
        p.lineTo(943, 199);
        p.lineTo(951, 201);
        p.lineTo(957, 209);
        p.lineTo(955, 216);
        p.lineTo(948, 221);
        p.lineTo(945, 231);
        p.lineTo(939, 237);
        p.lineTo(931, 237);
        p.lineTo(920, 236);
        p.lineTo(912, 240);
        p.lineTo(901, 241);
        p.lineTo(893, 240);
        p.lineTo(885, 231);
        p.lineTo(880, 235);
        p.lineTo(867, 237);
        p.lineTo(861, 230);
        p.lineTo(855, 233);
        p.lineTo(846, 232);
        p.lineTo(836, 234);
        p.close();

        // 8. Îlot 7
        p.moveTo(890, 351);
        p.lineTo(883, 357);
        p.lineTo(888, 363);
        p.lineTo(895, 363);
        p.lineTo(907, 359);
        p.lineTo(920, 364);
        p.lineTo(930, 359);
        p.lineTo(933, 351);
        p.lineTo(935, 345);
        p.lineTo(925, 339);
        p.lineTo(920, 329);
        p.lineTo(911, 331);
        p.lineTo(908, 336);
        p.lineTo(903, 336);
        p.lineTo(901, 343);
        p.lineTo(893, 343);
        p.close();

        // 9. Îlot 8
        p.moveTo(875, 387);
        p.lineTo(870, 393);
        p.lineTo(865, 398);
        p.lineTo(870, 403);
        p.lineTo(877, 405);
        p.lineTo(881, 397);
        p.lineTo(884, 389);
        p.close();

        return p;
      }(),
    ),
    RegionShape(
      id: 'montagnes',
      name: 'Sommets des Montagnes',
      color: const Color(0xFF4F9A5B),
      path: () {
        final p = Path();

        // 1. Continent principal des montagnes
        p.moveTo(410, 736);
        p.lineTo(412, 746);
        p.lineTo(415, 756);
        p.lineTo(423, 767);
        p.lineTo(427, 781);
        p.lineTo(428, 797);
        p.lineTo(429, 818);
        p.lineTo(430, 833);
        p.lineTo(431, 853);
        p.lineTo(434, 871);
        p.lineTo(430, 891);
        p.lineTo(425, 904);
        p.lineTo(420, 913);
        p.lineTo(422, 926);
        p.lineTo(420, 941);
        p.lineTo(411, 960);
        p.lineTo(406, 971);
        p.lineTo(404, 980);
        p.lineTo(396, 998);
        p.lineTo(390, 1006);
        p.lineTo(381, 1021);
        p.lineTo(373, 1036);
        p.lineTo(368, 1047);
        p.lineTo(353, 1061);
        p.lineTo(341, 1075);
        p.lineTo(330, 1093);
        p.lineTo(318, 1105);
        p.lineTo(305, 1119);
        p.lineTo(293, 1126);
        p.lineTo(288, 1142);
        p.lineTo(286, 1167);
        p.lineTo(289, 1182);
        p.lineTo(298, 1201);
        p.lineTo(314, 1212);
        p.lineTo(327, 1213);
        p.lineTo(340, 1211);
        p.lineTo(344, 1199);
        p.lineTo(354, 1186);
        p.lineTo(367, 1184);
        p.lineTo(378, 1181);
        p.lineTo(388, 1170);
        p.lineTo(403, 1171);
        p.lineTo(419, 1172);
        p.lineTo(437, 1166);
        p.lineTo(454, 1163);
        p.lineTo(474, 1163);
        p.lineTo(496, 1163);
        p.lineTo(515, 1179);
        p.lineTo(525, 1186);
        p.lineTo(530, 1192);
        p.lineTo(539, 1205);
        p.lineTo(550, 1214);
        p.lineTo(560, 1216);
        p.lineTo(566, 1226);
        p.lineTo(580, 1235);
        p.lineTo(590, 1235);
        p.lineTo(602, 1245);
        p.lineTo(614, 1252);
        p.lineTo(628, 1253);
        p.lineTo(645, 1250);
        p.lineTo(653, 1241);
        p.lineTo(656, 1232);
        p.lineTo(657, 1221);
        p.lineTo(654, 1207);
        p.lineTo(660, 1197);
        p.lineTo(666, 1189);
        p.lineTo(667, 1175);
        p.lineTo(674, 1163);
        p.lineTo(684, 1151);
        p.lineTo(689, 1139);
        p.lineTo(699, 1131);
        p.lineTo(701, 1119);
        p.lineTo(700, 1108);
        p.lineTo(701, 1097);
        p.lineTo(706, 1089);
        p.lineTo(706, 1076);
        p.lineTo(720, 1071);
        p.lineTo(730, 1068);
        p.lineTo(741, 1063);
        p.lineTo(750, 1053);
        p.lineTo(755, 1044);
        p.lineTo(762, 1032);
        p.lineTo(774, 1028);
        p.lineTo(789, 1018);
        p.lineTo(795, 1011);
        p.lineTo(799, 1000);
        p.lineTo(806, 989);
        p.lineTo(819, 981);
        p.lineTo(830, 971);
        p.lineTo(836, 957);
        p.lineTo(840, 941);
        p.lineTo(848, 923);
        p.lineTo(860, 904);
        p.lineTo(847, 901);
        p.lineTo(834, 900);
        p.lineTo(811, 897);
        p.lineTo(790, 892);
        p.lineTo(780, 881);
        p.lineTo(766, 872);
        p.lineTo(759, 862);
        p.lineTo(748, 854);
        p.lineTo(737, 841);
        p.lineTo(726, 834);
        p.lineTo(710, 833);
        p.lineTo(690, 834);
        p.lineTo(671, 832);
        p.lineTo(651, 827);
        p.lineTo(638, 819);
        p.lineTo(629, 803);
        p.lineTo(617, 786);
        p.lineTo(610, 765);
        p.lineTo(600, 742);
        p.lineTo(584, 741);
        p.lineTo(566, 734);
        p.lineTo(555, 716);
        p.lineTo(552, 700);
        p.lineTo(539, 678);
        p.lineTo(525, 671);
        p.lineTo(510, 676);
        p.lineTo(505, 681);
        p.lineTo(497, 689);
        p.lineTo(488, 692);
        p.lineTo(476, 701);
        p.lineTo(463, 708);
        p.lineTo(455, 715);
        p.lineTo(445, 721);
        p.lineTo(425, 728);
        p.close();

        // 2. Première île des montagnes
        p.moveTo(453, 1343);
        p.lineTo(442, 1346);
        p.lineTo(431, 1345);
        p.lineTo(429, 1337);
        p.lineTo(425, 1330);
        p.lineTo(425, 1318);
        p.lineTo(429, 1311);
        p.lineTo(436, 1306);
        p.lineTo(443, 1301);
        p.lineTo(446, 1295);
        p.lineTo(443, 1287);
        p.lineTo(447, 1278);
        p.lineTo(449, 1268);
        p.lineTo(443, 1264);
        p.lineTo(438, 1254);
        p.lineTo(434, 1243);
        p.lineTo(424, 1236);
        p.lineTo(418, 1223);
        p.lineTo(424, 1218);
        p.lineTo(434, 1211);
        p.lineTo(448, 1211);
        p.lineTo(458, 1201);
        p.lineTo(469, 1207);
        p.lineTo(483, 1209);
        p.lineTo(490, 1221);
        p.lineTo(498, 1224);
        p.lineTo(504, 1235);
        p.lineTo(514, 1243);
        p.lineTo(521, 1251);
        p.lineTo(520, 1261);
        p.lineTo(525, 1275);
        p.lineTo(528, 1283);
        p.lineTo(523, 1286);
        p.lineTo(519, 1293);
        p.lineTo(511, 1301);
        p.lineTo(503, 1311);
        p.lineTo(491, 1319);
        p.lineTo(489, 1326);
        p.lineTo(484, 1331);
        p.lineTo(476, 1337);
        p.lineTo(469, 1341);
        p.close();

        // 3. Deuxième île satellite
        p.moveTo(767, 1125);
        p.lineTo(769, 1114);
        p.lineTo(768, 1106);
        p.lineTo(775, 1101);
        p.lineTo(783, 1094);
        p.lineTo(790, 1094);
        p.lineTo(800, 1091);
        p.lineTo(810, 1093);
        p.lineTo(819, 1095);
        p.lineTo(824, 1102);
        p.lineTo(828, 1110);
        p.lineTo(828, 1118);
        p.lineTo(825, 1127);
        p.lineTo(824, 1140);
        p.lineTo(819, 1156);
        p.lineTo(814, 1165);
        p.lineTo(808, 1170);
        p.lineTo(800, 1174);
        p.lineTo(793, 1180);
        p.lineTo(781, 1176);
        p.lineTo(775, 1167);
        p.lineTo(773, 1160);
        p.lineTo(767, 1151);
        p.lineTo(757, 1148);
        p.lineTo(753, 1141);
        p.lineTo(753, 1134);
        p.lineTo(759, 1132);
        p.close();

        // 4. Troisième île satellite
        p.moveTo(820, 1186);
        p.lineTo(827, 1188);
        p.lineTo(834, 1188);
        p.lineTo(836, 1194);
        p.lineTo(837, 1201);
        p.lineTo(837, 1209);
        p.lineTo(840, 1216);
        p.lineTo(835, 1223);
        p.lineTo(831, 1228);
        p.lineTo(822, 1227);
        p.lineTo(810, 1225);
        p.lineTo(803, 1222);
        p.lineTo(805, 1212);
        p.lineTo(808, 1204);
        p.lineTo(802, 1195);
        p.lineTo(811, 1190);
        p.close();

        return p;
      }(),
    ),
  ];
}