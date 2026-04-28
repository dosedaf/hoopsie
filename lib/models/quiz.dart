class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? imageUrl;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
  });
}

final List<QuizQuestion> quizQuestions = [
  QuizQuestion(
    question: 'Berapa poin nilai tembakan three-point?',
    options: ['1 poin', '2 poin', '3 poin', '4 poin'],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Berapa durasi satu quarter di NBA?',
    options: ['10 menit', '12 menit', '15 menit', '20 menit'],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Apa nama pelanggaran berjalan tanpa dribble?',
    options: ['Foul', 'Traveling', 'Double Dribble', 'Goaltending'],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Berapa tinggi standar ring basket dari lantai?',
    options: ['2,85 m', '3,05 m', '3,25 m', '3,50 m'],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Siapa yang mencetak 100 poin dalam satu game NBA?',
    options: ['Michael Jordan', 'Kobe Bryant', 'Wilt Chamberlain', 'LeBron James'],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Berapa shot clock di NBA (detik)?',
    options: ['14', '18', '24', '30'],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Posisi yang bertugas mengatur serangan disebut?',
    options: ['Small Forward', 'Power Forward', 'Point Guard', 'Center'],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Tim mana yang paling banyak juara NBA sepanjang sejarah?',
    options: ['LA Lakers', 'Boston Celtics', 'Chicago Bulls', 'Golden State Warriors'],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: '"Triple-double" berarti dua digit di tiga statistik apa?',
    options: ['Poin, rebound, assist', 'Poin, steal, block', 'Rebound, assist, foul', 'Poin, foul, turnover'],
    correctIndex: 0,
  ),
  QuizQuestion(
    question: 'Berapa pemain satu tim yang boleh di lapangan sekaligus?',
    options: ['4', '5', '6', '7'],
    correctIndex: 1,
  ),

  QuizQuestion(
    question: 'Siapa pemain ini?',
    options: ['Kevin Durant', 'LeBron James', 'Stephen Curry', 'Giannis'],
    correctIndex: 1,
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/LeBron_James_crop.jpg/440px-LeBron_James_crop.jpg',
  ),
  QuizQuestion(
    question: 'Siapa pemain ini?',
    options: ['Klay Thompson', 'Chris Paul', 'Stephen Curry', 'Damian Lillard'],
    correctIndex: 2,
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Stephen_Curry_2019.jpg/440px-Stephen_Curry_2019.jpg',
  ),
  QuizQuestion(
    question: 'Siapa pemain ini?',
    options: ['Kevin Durant', 'Kawhi Leonard', 'Paul George', 'Jimmy Butler'],
    correctIndex: 0,
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/99/Kevin_Durant_2_2022.jpg/440px-Kevin_Durant_2_2022.jpg',
  ),
  QuizQuestion(
    question: 'Siapa pemain ini?',
    options: ['LeBron James', 'Nikola Jokic', 'Joel Embiid', 'Giannis Antetokounmpo'],
    correctIndex: 3,
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Giannis_Antetokounmpo_2016.jpg/440px-Giannis_Antetokounmpo_2016.jpg',
  ),
  QuizQuestion(
    question: 'Siapa legenda ini?',
    options: ['Magic Johnson', 'Larry Bird', 'Michael Jordan', 'Scottie Pippen'],
    correctIndex: 2,
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Michael_Jordan_in_2014.jpg/440px-Michael_Jordan_in_2014.jpg',
  ),
  QuizQuestion(
    question: 'Siapa pemain ini?',
    options: ['Luka Doncic', 'Trae Young', 'Ja Morant', 'Shai Gilgeous-Alexander'],
    correctIndex: 0,
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Luka_Don%C4%8Di%C4%87_2022.jpg/440px-Luka_Don%C4%8Di%C4%87_2022.jpg',
  ),
]..shuffle();
