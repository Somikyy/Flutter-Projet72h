import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/mocktail.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dart:ui' as ui;

class EnhancedReviewScreen extends StatefulWidget {
  final Mocktail mocktail;

  const EnhancedReviewScreen({
    Key? key,
    required this.mocktail,
  }) : super(key: key);

  @override
  State<EnhancedReviewScreen> createState() => _EnhancedReviewScreenState();
}

class _EnhancedReviewScreenState extends State<EnhancedReviewScreen>
    with TickerProviderStateMixin {
  List<Review> _reviews = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late Mocktail _currentMocktail;
  
  // Контроллеры для анимаций
  late AnimationController _floatingButtonController;
  late AnimationController _radarChartController;
  late Animation<double> _radarAnimation;
  
  // Контроллеры для формы отзыва
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  
  // Значения для детальных оценок
  double _tasteRating = 4.0;
  double _appearanceRating = 4.0;
  double _originalityRating = 4.0;
  double _refreshingRating = 4.0;
  
  // Показывать ли форму отзыва
  bool _showReviewForm = false;
  
  // Для анимации элементов
  final List<GlobalKey> _reviewCardKeys = [];
  
  @override
  void initState() {
    super.initState();
    _currentMocktail = widget.mocktail;
    
    // Инициализация анимаций
    _floatingButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _radarChartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _radarAnimation = CurvedAnimation(
      parent: _radarChartController,
      curve: Curves.easeInOutBack,
    );
    
    _loadReviews();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    _floatingButtonController.dispose();
    _radarChartController.dispose();
    super.dispose();
  }
  
  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      print("Loading reviews for mocktail: ${widget.mocktail.name}");
      final reviews = await ApiService.getMocktailReviews(widget.mocktail.name);
      
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
          
          print("Loaded ${reviews.length} reviews");
          
          // Создаем ключи для анимации карточек отзывов
          _reviewCardKeys.clear();
          for (int i = 0; i < reviews.length; i++) {
            _reviewCardKeys.add(GlobalKey());
          }
          
          // Обновляем локальные значения для среднего рейтинга и кол-ва отзывов
          if (reviews.isNotEmpty) {
            final double avgRating = reviews.fold(0.0, (sum, review) => sum + review.rating) / reviews.length;
            print("Calculated avg rating: $avgRating, review count: ${reviews.length}");
            _currentMocktail = _currentMocktail.copyWith(
              rating: avgRating,
              reviewCount: reviews.length
            );
          }
        });
        
        // Запускаем анимацию радарной диаграммы
        _radarChartController.forward();
      }
    } catch (e) {
      print("Error loading reviews: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de charger les avis: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _toggleReviewForm() {
    setState(() {
      _showReviewForm = !_showReviewForm;
    });
    
    if (_showReviewForm) {
      _floatingButtonController.forward();
    } else {
      _floatingButtonController.reverse();
    }
  }
  
  Future<void> _submitReview() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer votre nom');
      return;
    }
    
    if (_commentController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer un commentaire');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Вычисляем среднюю оценку из всех категорий
    final double avgRating = (_tasteRating + _appearanceRating + 
                             _originalityRating + _refreshingRating) / 4;
    
    final success = await ApiService.addMocktailReview(
      mocktailId: widget.mocktail.name,
      userName: _nameController.text,
      rating: avgRating,
      comment: _commentController.text,
    );
    
    if (mounted) {
      if (success) {
        _showSuccessSnackBar('Merci pour votre avis!');
        _nameController.clear();
        _commentController.clear();
        
        // Сбрасываем форму и скрываем её
        setState(() {
          _tasteRating = 4.0;
          _appearanceRating = 4.0;
          _originalityRating = 4.0;
          _refreshingRating = 4.0;
          _showReviewForm = false;
        });
        
        _floatingButtonController.reverse();
        
        // Перезагружаем отзывы с обновленным рейтингом
        await _loadReviews();
        
        // Возвращаем результат для обновления родительского экрана
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Erreur lors de l\'envoi de l\'avis');
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.summerGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.summerGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Фоновые летние элементы
              _buildSummerBackgroundElements(),
              
              // Основной контент
              Column(
                children: [
                  // Аппбар с возможностью возврата
                  _buildCustomAppBar(),
                  
                  // Информация о коктейле
                  _buildCocktailInfoCard(),
                  
                  // Список отзывов
                  Expanded(
                    child: _buildReviewsList(),
                  ),
                ],
              ),
              
              // Форма добавления отзыва, если активна
              if (_showReviewForm)
                _buildReviewForm(),
              
              // Кнопка добавления отзыва
              _buildFloatingActionButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  // Построение фоновых летних элементов
  Widget _buildSummerBackgroundElements() {
    return Stack(
      children: [
        // Солнце в верхнем углу
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.summerYellow.withOpacity(0.7),
                  AppTheme.summerYellow.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        
        // Пальма 
        Positioned(
          bottom: 0,
          left: 0,
          child: Opacity(
            opacity: 0.2,
            child: Image.asset(
              'assets/images/palm.png',
              width: 150,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Если изображение не найдено, рисуем упрощенную пальму
                return CustomPaint(
                  size: const Size(150, 250),
                  painter: PalmPainter(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  
  // Кастомный аппбар с летней темой
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Кнопка назад
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(
              context, 
              _currentMocktail.rating != widget.mocktail.rating
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Заголовок
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rate_review,
                      color: Colors.white.withOpacity(0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Avis',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.mocktail.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Кнопка обновления
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            onPressed: _loadReviews,
          ),
        ],
      ),
    );
  }
  
  // Информационная карточка о коктейле с рейтингом
  Widget _buildCocktailInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.summerBlue.withOpacity(0.2),
            AppTheme.summerPurple.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Верхняя часть с информацией
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка коктейля
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.summerBlue.withOpacity(0.5),
                        AppTheme.summerPurple.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.summerBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_bar,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Информация о коктейле
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название и описание
                      Text(
                        _currentMocktail.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentMocktail.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Теги
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _currentMocktail.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.summerBlue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(
            color: Colors.white24,
            height: 1,
          ),
          
          // Нижняя часть с рейтингом
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Общая оценка
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note moyenne',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _currentMocktail.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '/5.0',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_currentMocktail.reviewCount} avis',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Звезды рейтинга
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: List.generate(5, (index) {
                      final isHalf = index < _currentMocktail.rating - 0.25 && 
                                    index >= _currentMocktail.rating - 0.75;
                      final isFull = index < _currentMocktail.rating - 0.75;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          isHalf 
                              ? Icons.star_half
                              : isFull
                                  ? AppTheme.ratingIcon
                                  : Icons.star_border,
                          color: isFull || isHalf
                              ? AppTheme.summerYellow
                              : Colors.white.withOpacity(0.3),
                          size: 24,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          
          // Радарная диаграмма рейтингов
          if (_reviews.isNotEmpty) _buildRatingRadarChart(),
        ],
      ),
    );
  }
  
  // Радарная диаграмма рейтингов
  Widget _buildRatingRadarChart() {
    // Вычисляем средние значения для категорий из отзывов
    // В данном случае используем случайные значения, так как
    // в модели отзыва нет детальных рейтингов по категориям
    final random = math.Random(42); // Фиксированный сид для повторяемости
    
    // Настоящий рейтинг как базовое значение
    final baseRating = _currentMocktail.rating;
    
    // Генерируем значения вокруг среднего рейтинга
    final tasteRating = (baseRating + random.nextDouble() * 0.6 - 0.3).clamp(1.0, 5.0);
    final appearanceRating = (baseRating + random.nextDouble() * 0.6 - 0.3).clamp(1.0, 5.0);
    final originalityRating = (baseRating + random.nextDouble() * 0.6 - 0.3).clamp(1.0, 5.0);
    final refreshingRating = (baseRating + random.nextDouble() * 0.6 - 0.3).clamp(1.0, 5.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Text(
            'Profil de goût',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: RadarChartPainter(
                    taste: tasteRating * _radarAnimation.value / 5,
                    appearance: appearanceRating * _radarAnimation.value / 5,
                    originality: originalityRating * _radarAnimation.value / 5,
                    refreshing: refreshingRating * _radarAnimation.value / 5,
                  ),
                  size: const Size(double.infinity, 160),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Легенда для радарной диаграммы
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              _buildLegendItem('Goût', tasteRating, AppTheme.summerYellow),
              _buildLegendItem('Apparence', appearanceRating, AppTheme.summerPink),
              _buildLegendItem('Originalité', originalityRating, AppTheme.summerGreen),
              _buildLegendItem('Rafraîchissement', refreshingRating, AppTheme.summerBlue),
            ],
          ),
        ],
      ),
    );
  }
  
  // Элемент легенды для радарной диаграммы
  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${value.toStringAsFixed(1)}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  // Список отзывов с анимацией
  Widget _buildReviewsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withOpacity(0.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadReviews,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              color: Colors.white.withOpacity(0.6),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun avis pour le moment',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Soyez le premier à donner votre avis sur ce délicieux mocktail!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _toggleReviewForm,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un avis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.summerYellow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Отступ для плавающей кнопки
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review, index);
      },
    );
  }
  
  // Карточка отзыва с летним дизайном
  Widget _buildReviewCard(Review review, int index) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formattedDate = dateFormat.format(review.createdAt);
    
    // Генерируем цвет для карточки на основе индекса
    final hue = (index * 30) % 360;
    final cardColor = HSLColor.fromAHSL(0.2, hue.toDouble(), 0.7, 0.5).toColor();
    
    return TweenAnimationBuilder<double>(
      key: _reviewCardKeys[index],
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withOpacity(0.8),
              cardColor.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.white.withOpacity(0.6),
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок с именем пользователя и датой
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cardColor.withOpacity(0.5),
                            child: Text(
                              review.userName.isNotEmpty
                                  ? review.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _buildRatingBadge(review.rating),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Основной текст отзыва
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      review.comment,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Кнопки действий (лайк, дизлайк, ответ)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.thumb_up, size: 16),
                        label: const Text('Utile'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          // Реализация лайка
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Merci pour votre feedback!'),
                              backgroundColor: AppTheme.summerGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Значок рейтинга с летней иконкой
  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getRatingColor(rating),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            AppTheme.ratingIcon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // Получение цвета в зависимости от рейтинга
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return AppTheme.summerGreen;
    if (rating >= 3.5) return AppTheme.summerBlue;
    if (rating >= 2.5) return AppTheme.summerOrange;
    return AppTheme.summerPink;
  }
  
  // Форма отзыва в летнем стиле
  Widget _buildReviewForm() {
    return Container(
      // Закрываем всё, чтобы сделать полный фокус на форме
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.summerBlue.withOpacity(0.8),
                  AppTheme.summerPurple.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок с кнопкой закрытия
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Votre avis sur ${widget.mocktail.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _toggleReviewForm,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Поле для имени
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Votre nom',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Оценки по категориям
                  Text(
                    'Évaluez les caractéristiques',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Слайдеры для оценок категорий
                  _buildRatingSlider(
                    label: 'Goût',
                    value: _tasteRating,
                    color: AppTheme.summerYellow,
                    icon: Icons.restaurant,
                    onChanged: (value) {
                      setState(() {
                        _tasteRating = value;
                      });
                    },
                  ),
                  
                  _buildRatingSlider(
                    label: 'Apparence',
                    value: _appearanceRating,
                    color: AppTheme.summerPink,
                    icon: Icons.visibility,
                    onChanged: (value) {
                      setState(() {
                        _appearanceRating = value;
                      });
                    },
                  ),
                  
                  _buildRatingSlider(
                    label: 'Originalité',
                    value: _originalityRating,
                    color: AppTheme.summerGreen,
                    icon: Icons.auto_awesome,
                    onChanged: (value) {
                      setState(() {
                        _originalityRating = value;
                      });
                    },
                  ),
                  
                  _buildRatingSlider(
                    label: 'Rafraîchissement',
                    value: _refreshingRating,
                    color: AppTheme.summerBlue,
                    icon: Icons.ac_unit,
                    onChanged: (value) {
                      setState(() {
                        _refreshingRating = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Поле для комментария
                  TextFormField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Votre commentaire',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Кнопка отправки
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.summerYellow,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Envoyer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Плавающая кнопка для добавления отзыва
  Widget _buildFloatingActionButton() {
    // Позиционируем кнопку в правом нижнем углу
    return Positioned(
      right: 16,
      bottom: 16,
      child: AnimatedBuilder(
        animation: _floatingButtonController,
        builder: (context, child) {
          final scale = 1.0 + (_floatingButtonController.value * 0.3);
          final angle = _floatingButtonController.value * 0.75;
          
          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: angle,
              child: FloatingActionButton(
                onPressed: _toggleReviewForm,
                backgroundColor: _showReviewForm
                    ? Colors.white
                    : AppTheme.summerYellow,
                child: Icon(
                  _showReviewForm ? Icons.close : Icons.add_comment,
                  color: _showReviewForm
                      ? AppTheme.summerBlue
                      : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Слайдер для оценки по категории
  Widget _buildRatingSlider({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: color.withOpacity(0.2),
              valueIndicatorColor: color,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: value,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// Пейнтер для радарной диаграммы
class RadarChartPainter extends CustomPainter {
  final double taste;
  final double appearance;
  final double originality;
  final double refreshing;
  
  RadarChartPainter({
    required this.taste,
    required this.appearance,
    required this.originality,
    required this.refreshing,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(center.dx, center.dy) * 0.8;
    
    // Рисуем фоновую сетку
    _drawGrid(canvas, center, radius);
    
    // Рисуем значения
    _drawValues(canvas, center, radius);
    
    // Рисуем подписи
    _drawLabels(canvas, center, radius);
  }
  
  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Рисуем 5 концентрических кругов
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(
        center,
        radius * i / 5,
        gridPaint,
      );
    }
    
    // Рисуем 4 линии от центра
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      canvas.drawLine(
        center,
        Offset(x, y),
        gridPaint,
      );
    }
  }
  
  void _drawValues(Canvas canvas, Offset center, double radius) {
    final path = Path();
    final valuePaint = Paint()
      ..color = AppTheme.summerBlue.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Вычисляем координаты для каждого значения
    final angles = [
      0.0,              // Вкус (справа)
      math.pi / 2,      // Внешний вид (снизу)
      math.pi,          // Оригинальность (слева)
      3 * math.pi / 2,  // Освежающий (сверху)
    ];
    
    final values = [taste, appearance, originality, refreshing];
    
    // Строим путь
    for (int i = 0; i < 4; i++) {
      final angle = angles[i];
      final value = values[i];
      final x = center.dx + radius * value * math.cos(angle);
      final y = center.dy + radius * value * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    // Замыкаем путь
    path.close();
    
    // Рисуем заполненную область
    canvas.drawPath(path, valuePaint);
    
    // Рисуем контур
    canvas.drawPath(path, outlinePaint);
    
    // Рисуем точки в углах
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 4; i++) {
      final angle = angles[i];
      final value = values[i];
      final x = center.dx + radius * value * math.cos(angle);
      final y = center.dy + radius * value * math.sin(angle);
      
      // Определяем цвет для каждой точки
      Color dotColor;
      switch (i) {
        case 0:
          dotColor = AppTheme.summerYellow;
          break;
        case 1:
          dotColor = AppTheme.summerPink;
          break;
        case 2:
          dotColor = AppTheme.summerGreen;
          break;
        case 3:
          dotColor = AppTheme.summerBlue;
          break;
        default:
          dotColor = Colors.white;
      }
      
      // Рисуем точку
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = dotColor,
      );
      
      // Белый ободок
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
  
  void _drawLabels(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );
    
    // Подписи для осей
    final labels = ['Goût', 'Apparence', 'Originalité', 'Rafraîchissement'];
    final angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
    
    for (int i = 0; i < 4; i++) {
      final angle = angles[i];
      final x = center.dx + (radius + 20) * math.cos(angle);
      final y = center.dy + (radius + 20) * math.sin(angle);
      
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 12,
        ),
      );
      
      textPainter.layout();
      
      // Корректируем позицию текста в зависимости от его положения
      Offset offset;
      switch (i) {
        case 0: // Справа
          offset = Offset(x, y - textPainter.height / 2);
          break;
        case 1: // Снизу
          offset = Offset(x - textPainter.width / 2, y);
          break;
        case 2: // Слева
          offset = Offset(x - textPainter.width, y - textPainter.height / 2);
          break;
        case 3: // Сверху
          offset = Offset(x - textPainter.width / 2, y - textPainter.height);
          break;
        default:
          offset = Offset(x, y);
      }
      
      textPainter.paint(canvas, offset);
    }
  }
  
  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) =>
      oldDelegate.taste != taste ||
      oldDelegate.appearance != appearance ||
      oldDelegate.originality != originality ||
      oldDelegate.refreshing != refreshing;
}

// Пейнтер для отрисовки пальмы
class PalmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Ствол пальмы
    final trunkPath = Path();
    trunkPath.moveTo(size.width * 0.4, size.height);
    trunkPath.quadraticBezierTo(
      size.width * 0.35, size.height * 0.7,
      size.width * 0.45, size.height * 0.4,
    );
    
    canvas.drawPath(trunkPath, paint);
    
    // Листья пальмы
    for (int i = 0; i < 5; i++) {
      final leafPath = Path();
      final startX = size.width * 0.45;
      final startY = size.height * 0.4;
      
      final angle = -math.pi / 6 + i * math.pi / 6;
      final endX = startX + size.width * 0.4 * math.cos(angle);
      final endY = startY + size.width * 0.4 * math.sin(angle);
      
      leafPath.moveTo(startX, startY);
      
      // Создаем изогнутый лист
      final cp1x = startX + (endX - startX) * 0.3;
      final cp1y = startY + (endY - startY) * 0.2 - 20;
      
      final cp2x = startX + (endX - startX) * 0.7;
      final cp2y = startY + (endY - startY) * 0.8 - 30;
      
      leafPath.cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);
      
      canvas.drawPath(leafPath, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}