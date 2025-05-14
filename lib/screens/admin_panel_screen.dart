import 'package:flutter/material.dart';
import '../models/ingridient_level.dart';
import '../models/review.dart';
import '../models/mocktail.dart';
import '../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with TickerProviderStateMixin {
  // Contrôleur de tabs
  late TabController _tabController;
  
  // État de chargement global
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Vérifier d'abord si le serveur est accessible
    _checkServerConnection();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Vérification de la connexion au serveur
  Future<void> _checkServerConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final isConnected = await ApiService.checkServerStatus();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!isConnected) {
            _errorMessage = 'Impossible de se connecter au serveur. Veuillez vérifier votre connexion.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de connexion: $e';
        });
      }
    }
  }
  
  // Confirmation avant de quitter
  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le panneau d\'administration?'),
        content: const Text('Toutes les modifications non enregistrées seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panneau d\'administration'),
          automaticallyImplyLeading: false,
          actions: [
            // Bouton pour fermer l'admin panel
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _onWillPop().then((result) {
                if (result) Navigator.pop(context);
              }),
              tooltip: 'Quitter le mode administrateur',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.inventory_2), text: 'Ingrédients'),
              Tab(icon: Icon(Icons.comment), text: 'Avis'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Commandes'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E1437), Color(0xFF1A1A1A)],
            ),
          ),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Onglet Gestion des Ingrédients
                    IngredientsManagementTab(),
                    
                    // Onglet Gestion des Avis
                    ReviewsManagementTab(),
                    
                    // Onglet Gestion des Commandes
                    OrdersManagementTab(),
                  ],
                ),
        ),
      ),
    );
  }
  
  // Affichage en cas d'erreur
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkServerConnection,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// Tab pour la gestion des ingrédients
class IngredientsManagementTab extends StatefulWidget {
  @override
  State<IngredientsManagementTab> createState() => _IngredientsManagementTabState();
}

class _IngredientsManagementTabState extends State<IngredientsManagementTab> {
  List<IngredientLevel> _ingredients = [];
  Map<String, int> _updatedLevels = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }
  
  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _updatedLevels = {};
    });
    
    try {
      final ingredients = await ApiService.getIngredientsLevels();
      setState(() {
        _ingredients = ingredients;
        _isLoading = false;
        
        // Initialisation des valeurs
        for (var ingredient in ingredients) {
          _updatedLevels[ingredient.ingredientId] = ingredient.currentLevel;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveIngredientLevels() async {
    if (_updatedLevels.isEmpty) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final success = await ApiService.updateIngredientLevels(_updatedLevels);
      
      setState(() {
        _isSaving = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Niveaux d\'ingrédients mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Rechargement pour afficher les données mises à jour
        _loadIngredients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour des niveaux'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _updateIngredientLevel(String ingredientId, int newLevel) {
    setState(() {
      _updatedLevels[ingredientId] = newLevel;
    });
  }
  
  void _resetToMaxLevel(String ingredientId, int maxLevel) {
    setState(() {
      _updatedLevels[ingredientId] = maxLevel;
    });
  }
  
  void _incrementLevel(String ingredientId, int maxLevel) {
    final currentLevel = _updatedLevels[ingredientId] ?? 0;
    final newLevel = currentLevel + 50 > maxLevel ? maxLevel : currentLevel + 50;
    setState(() {
      _updatedLevels[ingredientId] = newLevel;
    });
  }
  
  void _decrementLevel(String ingredientId) {
    final currentLevel = _updatedLevels[ingredientId] ?? 0;
    final newLevel = currentLevel - 50 < 0 ? 0 : currentLevel - 50;
    setState(() {
      _updatedLevels[ingredientId] = newLevel;
    });
  }
  
  bool get _hasChanges {
    for (var ingredient in _ingredients) {
      final updatedLevel = _updatedLevels[ingredient.ingredientId];
      if (updatedLevel != null && updatedLevel != ingredient.currentLevel) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadIngredients,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Titre de section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Niveaux des ingrédients',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Bouton de rafraîchissement
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadIngredients,
                tooltip: 'Actualiser',
              ),
            ],
          ),
        ),
        
        // Liste des ingrédients
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = _ingredients[index];
              final currentLevel = _updatedLevels[ingredient.ingredientId] ?? ingredient.currentLevel;
              final percentFilled = currentLevel / ingredient.maxLevel;
              final Color levelColor = _getLevelColor(percentFilled);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom de l'ingrédient et boutons d'action rapide
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ingredient.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Bouton de remplissage au maximum
                          IconButton(
                            icon: const Icon(Icons.vertical_align_top, color: Colors.white),
                            onPressed: () => _resetToMaxLevel(
                              ingredient.ingredientId, 
                              ingredient.maxLevel
                            ),
                            tooltip: 'Remplir au maximum',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Information sur le niveau actuel et maximum
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Niveau actuel: $currentLevel ml',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Max: ${ingredient.maxLevel} ml',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Slider et boutons de changement de niveau
                      Row(
                        children: [
                          // Bouton de diminution
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.white),
                            onPressed: currentLevel > 0
                                ? () => _decrementLevel(ingredient.ingredientId)
                                : null,
                            style: IconButton.styleFrom(
                              disabledForegroundColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          
                          // Slider
                          Expanded(
                            child: Slider(
                              value: currentLevel.toDouble(),
                              min: 0,
                              max: ingredient.maxLevel.toDouble(),
                              divisions: ingredient.maxLevel ~/ 10, // Pas de 10 ml
                              activeColor: levelColor,
                              inactiveColor: levelColor.withOpacity(0.3),
                              label: '$currentLevel ml',
                              onChanged: (newValue) {
                                _updateIngredientLevel(
                                  ingredient.ingredientId,
                                  newValue.round(),
                                );
                              },
                            ),
                          ),
                          
                          // Bouton d'augmentation
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.white),
                            onPressed: currentLevel < ingredient.maxLevel
                                ? () => _incrementLevel(
                                    ingredient.ingredientId, 
                                    ingredient.maxLevel
                                  )
                                : null,
                            style: IconButton.styleFrom(
                              disabledForegroundColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                      
                      // Indicateur visuel du niveau
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentFilled,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Pourcentage de remplissage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(percentFilled * 100).toInt()}%',
                              style: TextStyle(
                                color: levelColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bouton d'enregistrement en bas de l'écran
        if (_hasChanges)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveIngredientLevels,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enregistrer les modifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
  
  Color _getLevelColor(double percent) {
    if (percent <= 0.2) return Colors.red;
    if (percent <= 0.4) return Colors.orange;
    if (percent <= 0.6) return Colors.yellow;
    return Colors.green;
  }
}

// Tab pour la gestion des avis
class ReviewsManagementTab extends StatefulWidget {
  @override
  State<ReviewsManagementTab> createState() => _ReviewsManagementTabState();
}

class _ReviewsManagementTabState extends State<ReviewsManagementTab> {
  List<Mocktail> _mocktails = [];
  Map<String, List<Review>> _reviewsByMocktail = {};
  String? _selectedMocktailId;
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadMocktails();
  }
  
  Future<void> _loadMocktails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final mocktails = await ApiService.getMocktails();
      
      if (mounted) {
        setState(() {
          _mocktails = mocktails;
          _isLoading = false;
          
          // Sélectionner automatiquement le premier mocktail s'il y en a
          if (mocktails.isNotEmpty && _selectedMocktailId == null) {
            _selectedMocktailId = mocktails.first.name;
            _loadReviewsForMocktail(_selectedMocktailId!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement des mocktails: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadReviewsForMocktail(String mocktailId) async {
    if (_reviewsByMocktail.containsKey(mocktailId)) {
      // Déjà chargé
      return;
    }
    
    setState(() {
      _isLoadingReviews = true;
    });
    
    try {
      final reviews = await ApiService.getMocktailReviews(mocktailId);
      
      if (mounted) {
        setState(() {
          _reviewsByMocktail[mocktailId] = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reviewsByMocktail[mocktailId] = [];
          _isLoadingReviews = false;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de chargement des avis: $e'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }
  
  Future<void> _deleteReview(String mocktailId, String reviewId) async {
    // Confirmation de suppression
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet avis?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoadingReviews = true;
    });
    
    try {
      // Appel à l'API pour supprimer l'avis (à implémenter dans ApiService)
      final success = await ApiService.deleteReview(mocktailId, reviewId);
      
      if (mounted) {
        if (success) {
          // Mettre à jour la liste locale
          setState(() {
            _reviewsByMocktail[mocktailId]?.removeWhere((review) => review.id == reviewId);
            _isLoadingReviews = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avis supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isLoadingReviews = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression de l\'avis'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showEditReviewDialog(String mocktailId, Review review) {
    final commentController = TextEditingController(text: review.comment);
    double rating = review.rating;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Modifier l\'avis'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations sur l'auteur et la date
                  Text(
                    'Auteur: ${review.userName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Date: ${review.createdAt.toLocal().toString().split('.')[0]}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Édition de la note
                  const Text(
                    'Note:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: rating,
                          min: 1.0,
                          max: 5.0,
                          divisions: 8,
                          label: rating.toStringAsFixed(1),
                          onChanged: (value) {
                            setDialogState(() {
                              rating = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Édition du commentaire
                  const Text(
                    'Commentaire:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Commentaire',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateReview(
                    mocktailId,
                    review.id,
                    rating,
                    commentController.text,
                  );
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _updateReview(String mocktailId, String reviewId, double rating, String comment) async {
    setState(() {
      _isLoadingReviews = true;
    });
    
    try {
      // Appel à l'API pour modifier l'avis (à implémenter dans ApiService)
      final success = await ApiService.updateReview(
        mocktailId: mocktailId,
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );
      
      if (mounted) {
        if (success) {
          // Mettre à jour la liste locale
          setState(() {
            final index = _reviewsByMocktail[mocktailId]?.indexWhere(
              (r) => r.id == reviewId
            );
            
            if (index != null && index >= 0) {
              final updatedReview = _reviewsByMocktail[mocktailId]![index];
              _reviewsByMocktail[mocktailId]![index] = Review(
                id: updatedReview.id,
                mocktailId: updatedReview.mocktailId,
                userName: updatedReview.userName,
                rating: rating,
                comment: comment,
                createdAt: updatedReview.createdAt,
              );
            }
            
            _isLoadingReviews = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avis modifié avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isLoadingReviews = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la modification de l\'avis'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMocktails,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (_mocktails.isEmpty) {
      return const Center(
        child: Text(
          'Aucun mocktail disponible',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return Column(
      children: [
        // Sélecteur de mocktail
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Mocktail: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedMocktailId,
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    underline: Container(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMocktailId = value;
                        });
                        _loadReviewsForMocktail(value);
                      }
                    },
                    items: _mocktails.map((mocktail) {
                      return DropdownMenuItem<String>(
                        value: mocktail.name,
                        child: Text(mocktail.name),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  if (_selectedMocktailId != null) {
                    // Réinitialiser pour forcer le rechargement
                    setState(() {
                      _reviewsByMocktail.remove(_selectedMocktailId);
                    });
                    _loadReviewsForMocktail(_selectedMocktailId!);
                  }
                },
                tooltip: 'Actualiser les avis',
              ),
            ],
          ),
        ),
        
        // Liste des avis
        Expanded(
          child: _isLoadingReviews
              ? const Center(child: CircularProgressIndicator())
              : _buildReviewsList(),
        ),
      ],
    );
  }
  
  Widget _buildReviewsList() {
    if (_selectedMocktailId == null) {
      return const Center(
        child: Text(
          'Sélectionnez un mocktail',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    final reviews = _reviewsByMocktail[_selectedMocktailId] ?? [];
    
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun avis pour ${_selectedMocktailId}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Entête avec infos utilisateur et date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.3),
                          child: Text(
                            review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                              '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Notation
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRatingColor(review.rating),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            review.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Contenu de l'avis
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review.comment,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Boutons d'actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bouton d'édition
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.blue.withOpacity(0.7)),
                      ),
                      onPressed: () => _showEditReviewDialog(_selectedMocktailId!, review),
                    ),
                    const SizedBox(width: 8),
                    // Bouton de suppression
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.red.withOpacity(0.7)),
                      ),
                      onPressed: () => _deleteReview(_selectedMocktailId!, review.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.blue;
    if (rating >= 2.5) return Colors.orange;
    return Colors.red;
  }
}

// Tab pour la gestion des commandes
class OrdersManagementTab extends StatefulWidget {
  @override
  State<OrdersManagementTab> createState() => _OrdersManagementTabState();
}

class _OrdersManagementTabState extends State<OrdersManagementTab> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _selectedOrder;
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
void _loadOrders() async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
    _selectedOrder = null;
  });
  
  try {
    final response = await ApiService.getOrders();
    
    if (mounted) {
      setState(() {
        // Conversion explicite de List<dynamic> en List<Map<String, dynamic>>
        if (response['orders'] != null && response['orders'] is List) {
          _orders = List<Map<String, dynamic>>.from(
            (response['orders'] as List).map((item) => 
              item is Map<String, dynamic> ? item : <String, dynamic>{}
            )
          );
        } else {
          _orders = [];
        }
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _errorMessage = 'Erreur de chargement des commandes: $e';
        _isLoading = false;
      });
    }
  }
}
  
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Appel à l'API pour mettre à jour le statut de la commande
      final success = await ApiService.updateOrderStatus(orderId, newStatus);
      
      if (mounted) {
        if (success) {
          // Recharger les commandes pour obtenir les données mises à jour
          _loadOrders();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Statut de la commande mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la mise à jour du statut de la commande'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showOrderDetails(Map<String, dynamic> order) {
    setState(() {
      _selectedOrder = order;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande disponible',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: _loadOrders,
            ),
          ],
        ),
      );
    }
    
    return Row(
      children: [
        // Liste des commandes (1/3 de l'écran)
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Entête
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(  // Ajoute un Expanded pour permettre au texte de s'adapter
                        child: const Text(
                          'Commandes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,  // Ajoute ellipsis si le texte est trop long
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadOrders,
                        tooltip: 'Actualiser',
                        iconSize: 20,  // Réduit légèrement la taille de l'icône
                      ),
                    ],
                  ),
                ),
                
                // Liste des commandes
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final isSelected = _selectedOrder != null && 
                                        _selectedOrder!['order_id'] == order['order_id'];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected 
                            ? Colors.blue.withOpacity(0.3) 
                            : Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isSelected
                              ? const BorderSide(color: Colors.blue, width: 2)
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          onTap: () => _showOrderDetails(order),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ID de commande et statut
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Utilise Expanded pour le texte afin qu'il puisse rétrécir si nécessaire
                                    Expanded(
                                      child: Text(
                                        'Commande: ${order['order_id']?.toString().substring(0, 8) ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis, // Permet de couper le texte avec ...
                                      ),
                                    ),
                                    // Ajoute un peu d'espace entre le texte et le badge
                                    const SizedBox(width: 8),
                                    // Le badge de statut reste tel quel
                                    _buildStatusBadge(order['status'] ?? 'unknown'),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Nom du mocktail
                                Text(
                                  order['mocktail_name'] ?? 'Mocktail inconnu',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                
                                const SizedBox(height: 4),
                                
                                // Date de la commande
                                if (order['timestamp'] != null)
                                  Text(
                                    _formatTimestamp(order['timestamp']),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                
                                const SizedBox(height: 4),
                                
                                // Volume total
                                Text(
                                  'Volume: ${order['total_volume'] ?? '?'} ml',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Détails de la commande sélectionnée (2/3 de l'écran)
        Expanded(
          flex: 2,
          child: _selectedOrder == null
              ? Center(
                  child: Text(
                    'Sélectionnez une commande pour voir les détails',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                )
              : _buildOrderDetails(),
        ),
      ],
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'received':
        color = Colors.blue;
        text = 'Reçue';
        icon = Icons.receipt;
        break;
      case 'processing':
        color = Colors.orange;
        text = 'En cours';
        icon = Icons.hourglass_top;
        break;
      case 'completed':
        color = Colors.green;
        text = 'Terminée';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Annulée';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'Inconnue';
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderDetails() {
    final order = _selectedOrder!;
    final ingredients = order['ingredients'] as Map<String, dynamic>? ?? {};
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entête avec ID de commande et statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Détails de la commande ${order['order_id']?.toString().substring(0, 8) ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(order['status'] ?? 'unknown'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations de base
          Card(
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Mocktail', order['mocktail_name'] ?? 'Inconnu', Icons.local_drink),
                  _buildInfoRow('Date', _formatTimestamp(order['timestamp']), Icons.calendar_today),
                  _buildInfoRow('Volume total', '${order['total_volume'] ?? '?'} ml', Icons.straighten),
                  _buildInfoRow('Statut actuel', order['status'] ?? 'Inconnu', Icons.info),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Titre section ingrédients
          const Text(
            'Ingrédients',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Liste des ingrédients
          Expanded(
            child: Card(
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ingredients.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun ingrédient disponible',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final entry = ingredients.entries.elementAt(index);
                        final ingredientName = entry.key;
                        final amount = entry.value;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getIngredientColor(ingredientName),
                            child: Text(
                              ingredientName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            ingredientName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Text(
                            '$amount ml',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action pour changer le statut
          Wrap(
  alignment: WrapAlignment.end,
  spacing: 8,
  runSpacing: 8,
  children: [
    OutlinedButton.icon(
      icon: const Icon(Icons.cancel, size: 16),
      label: const Text('Annuler'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
      ),
      onPressed: () => _updateOrderStatus(order['order_id'], 'cancelled'),
    ),
    OutlinedButton.icon(
      icon: const Icon(Icons.hourglass_top, size: 16),
      label: const Text('En cours'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange,
        side: const BorderSide(color: Colors.orange),
      ),
      onPressed: () => _updateOrderStatus(order['order_id'], 'processing'),
    ),
    ElevatedButton.icon(
      icon: const Icon(Icons.check_circle, size: 16),
      label: const Text('Terminer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _updateOrderStatus(order['order_id'], 'completed'),
    ),
  ],
),
        ],
      ),
    );
  }
  
Widget _buildInfoRow(String label, String value, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        // Titre
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        // Valeur avec Expanded pour éviter le débordement
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';
    
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(
        (timestamp is double ? timestamp * 1000 : timestamp) as int
      );
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date invalide';
    }
  }
  
  Color _getIngredientColor(String name) {
    if (name.contains('Cranberry')) return Colors.red.shade400;
    if (name.contains('Grenadine')) return Colors.red.shade300;
    if (name.contains('Citron')) return Colors.yellow.shade400;
    if (name.contains('Sprite')) return Colors.blue.shade300;
    return Colors.purple.shade300;
  }
}