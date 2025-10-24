/**
 * Category Manager Component
 * Manage transaction categories with add, edit, delete operations
 */

import * as AlertDialog from '@radix-ui/react-alert-dialog';
import * as Dialog from '@radix-ui/react-dialog';
import * as RadioGroup from '@radix-ui/react-radio-group';
import { useEffect, useState } from 'react';
import {
  type Category,
  type CreateCategoryInput,
  createCategory,
  deleteCategory,
  getAllCategories,
  updateCategory,
} from '@/core/services/categoryService';
import './CategoryManager.css';

// Available icons for categories
const CATEGORY_ICONS = [
  '💼',
  '💻',
  '📈',
  '🏢',
  '🏠',
  '💰', // Income
  '🍔',
  '🛒',
  '🚗',
  '🛍️',
  '🎬',
  '📄', // Expense 1
  '🏥',
  '📚',
  '✈️',
  '🛡️',
  '📱',
  '💸', // Expense 2
  '⚡',
  '🎮',
  '🎵',
  '🎨',
  '🏋️',
  '☕', // Additional
];

// Available colors for categories
const CATEGORY_COLORS = [
  '#10B981', // Green (Income default)
  '#EF4444', // Red (Expense default)
  '#3B82F6', // Blue
  '#F59E0B', // Amber
  '#8B5CF6', // Purple
  '#EC4899', // Pink
  '#06B6D4', // Cyan
  '#84CC16', // Lime
];

export function CategoryManager() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [selectedType, setSelectedType] = useState<'income' | 'expense'>(
    'income'
  );
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [categoryToDelete, setCategoryToDelete] = useState<Category | null>(
    null
  );

  // Alert Dialog state
  const [alertDialog, setAlertDialog] = useState<{
    isOpen: boolean;
    title: string;
    description: string;
    variant: 'success' | 'error';
  }>({
    isOpen: false,
    title: '',
    description: '',
    variant: 'success',
  });

  // Form state
  const [formData, setFormData] = useState<CreateCategoryInput>({
    name: '',
    type: 'income',
    icon: '💰',
    color: '#10B981',
  });

  // Load categories
  useEffect(() => {
    loadCategories();
  }, []);

  const showAlert = (
    title: string,
    description: string,
    variant: 'success' | 'error' = 'success'
  ) => {
    setAlertDialog({
      isOpen: true,
      title,
      description,
      variant,
    });
  };

  const loadCategories = async () => {
    try {
      setIsLoading(true);
      const data = await getAllCategories();
      setCategories(data);
    } catch (error) {
      console.error('Failed to load categories:', error);
      showAlert(
        'Error',
        'Failed to load categories. Please try again.',
        'error'
      );
    } finally {
      setIsLoading(false);
    }
  };

  // Filter categories by type
  const filteredCategories = categories.filter(
    (cat) => cat.type === selectedType
  );

  // Handlers
  const handleAddCategory = () => {
    setEditingCategory(null);
    setFormData({
      name: '',
      type: selectedType,
      icon: selectedType === 'income' ? '💰' : '💸',
      color: selectedType === 'income' ? '#10B981' : '#EF4444',
    });
    setIsFormOpen(true);
  };

  const handleEditCategory = (category: Category) => {
    setEditingCategory(category);
    setFormData({
      name: category.name,
      type: category.type,
      icon: category.icon || '💰',
      color: category.color || '#10B981',
    });
    setIsFormOpen(true);
  };

  const handleDeleteClick = (category: Category) => {
    setCategoryToDelete(category);
    setIsDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!categoryToDelete) return;

    try {
      await deleteCategory(categoryToDelete.id);
      await loadCategories();
      setIsDeleteDialogOpen(false);
      setCategoryToDelete(null);
      showAlert('Success', 'Category deleted successfully', 'success');
    } catch (error) {
      console.error('Failed to delete category:', error);
      showAlert(
        'Error',
        'Failed to delete category. Default categories cannot be deleted.',
        'error'
      );
    }
  };

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.name.trim()) {
      showAlert('Validation Error', 'Please enter a category name', 'error');
      return;
    }

    try {
      if (editingCategory) {
        await updateCategory(editingCategory.id, formData);
        showAlert('Success', 'Category updated successfully', 'success');
      } else {
        await createCategory(formData);
        showAlert('Success', 'Category created successfully', 'success');
      }
      await loadCategories();
      setIsFormOpen(false);
      setEditingCategory(null);
    } catch (error) {
      console.error('Failed to save category:', error);
      showAlert('Error', 'Failed to save category. Please try again.', 'error');
    }
  };

  const handleCloseForm = () => {
    setIsFormOpen(false);
    setEditingCategory(null);
  };

  if (isLoading) {
    return (
      <div className="category-manager">
        <div className="category-manager__loading">Loading categories...</div>
      </div>
    );
  }

  return (
    <div className="category-manager">
      {/* Type Filter */}
      <div className="category-manager__filter">
        <button
          type="button"
          className={`category-manager__filter-btn ${
            selectedType === 'income' ? 'active' : ''
          }`}
          onClick={() => setSelectedType('income')}
        >
          💰 Income ({categories.filter((c) => c.type === 'income').length})
        </button>
        <button
          type="button"
          className={`category-manager__filter-btn ${
            selectedType === 'expense' ? 'active' : ''
          }`}
          onClick={() => setSelectedType('expense')}
        >
          💸 Expense ({categories.filter((c) => c.type === 'expense').length})
        </button>
      </div>

      {/* Add Button */}
      <div className="category-manager__header">
        <button
          type="button"
          className="category-manager__add-btn"
          onClick={handleAddCategory}
        >
          + Add Category
        </button>
      </div>

      {/* Categories Grid */}
      <div className="category-manager__grid">
        {filteredCategories.map((category) => (
          <div key={category.id} className="category-card">
            <div
              className="category-card__icon"
              style={{ backgroundColor: category.color }}
            >
              {category.icon}
            </div>
            <div className="category-card__content">
              <h4 className="category-card__name">{category.name}</h4>
              {category.is_default && (
                <span className="category-card__badge">Default</span>
              )}
            </div>
            <div className="category-card__actions">
              <button
                type="button"
                className="category-card__action-btn"
                onClick={() => handleEditCategory(category)}
                aria-label={`Edit ${category.name}`}
              >
                ✏️
              </button>
              {!category.is_default && (
                <button
                  type="button"
                  className="category-card__action-btn category-card__action-btn--danger"
                  onClick={() => handleDeleteClick(category)}
                  aria-label={`Delete ${category.name}`}
                >
                  🗑️
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      {filteredCategories.length === 0 && (
        <div className="category-manager__empty">
          <p>No {selectedType} categories yet</p>
          <button
            type="button"
            className="category-manager__add-btn"
            onClick={handleAddCategory}
          >
            Add Your First Category
          </button>
        </div>
      )}

      {/* Add/Edit Dialog */}
      <Dialog.Root open={isFormOpen} onOpenChange={handleCloseForm}>
        <Dialog.Portal>
          <Dialog.Overlay className="category-dialog__overlay" />
          <Dialog.Content className="category-dialog__content">
            <Dialog.Title className="category-dialog__title">
              {editingCategory ? 'Edit Category' : 'Add Category'}
            </Dialog.Title>

            <form onSubmit={handleFormSubmit} className="category-form">
              {/* Name Input */}
              <div className="category-form__field">
                <label htmlFor="category-name" className="category-form__label">
                  Name
                </label>
                <input
                  id="category-name"
                  type="text"
                  className="category-form__input"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                  placeholder="e.g., Groceries"
                  required
                />
              </div>

              {/* Type Selection */}
              <div className="category-form__field">
                <label className="category-form__label">Type</label>
                <RadioGroup.Root
                  value={formData.type}
                  onValueChange={(value) =>
                    setFormData({
                      ...formData,
                      type: value as 'income' | 'expense',
                      color: value === 'income' ? '#10B981' : '#EF4444',
                      icon: value === 'income' ? '💰' : '💸',
                    })
                  }
                  className="category-form__radio-group"
                >
                  <div className="category-form__radio-item">
                    <RadioGroup.Item
                      value="income"
                      className="category-form__radio-button"
                    >
                      <RadioGroup.Indicator className="category-form__radio-indicator" />
                    </RadioGroup.Item>
                    <label className="category-form__radio-label">
                      💰 Income
                    </label>
                  </div>
                  <div className="category-form__radio-item">
                    <RadioGroup.Item
                      value="expense"
                      className="category-form__radio-button"
                    >
                      <RadioGroup.Indicator className="category-form__radio-indicator" />
                    </RadioGroup.Item>
                    <label className="category-form__radio-label">
                      💸 Expense
                    </label>
                  </div>
                </RadioGroup.Root>
              </div>

              {/* Icon Picker */}
              <div className="category-form__field">
                <label className="category-form__label">Icon</label>
                <div className="category-form__icon-grid">
                  {CATEGORY_ICONS.map((icon) => (
                    <button
                      key={icon}
                      type="button"
                      className={`category-form__icon-btn ${
                        formData.icon === icon ? 'active' : ''
                      }`}
                      onClick={() => setFormData({ ...formData, icon })}
                    >
                      {icon}
                    </button>
                  ))}
                </div>
              </div>

              {/* Color Picker */}
              <div className="category-form__field">
                <label className="category-form__label">Color</label>
                <div className="category-form__color-grid">
                  {CATEGORY_COLORS.map((color) => (
                    <button
                      key={color}
                      type="button"
                      className={`category-form__color-btn ${
                        formData.color === color ? 'active' : ''
                      }`}
                      style={{ backgroundColor: color }}
                      onClick={() => setFormData({ ...formData, color })}
                      aria-label={`Select color ${color}`}
                    >
                      {formData.color === color && '✓'}
                    </button>
                  ))}
                </div>
              </div>

              {/* Preview */}
              <div className="category-form__preview">
                <div className="category-form__preview-label">Preview:</div>
                <div className="category-card category-card--preview">
                  <div
                    className="category-card__icon"
                    style={{ backgroundColor: formData.color }}
                  >
                    {formData.icon}
                  </div>
                  <div className="category-card__content">
                    <h4 className="category-card__name">
                      {formData.name || 'Category Name'}
                    </h4>
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="category-form__actions">
                <Dialog.Close asChild>
                  <button
                    type="button"
                    className="category-form__btn category-form__btn--secondary"
                  >
                    Cancel
                  </button>
                </Dialog.Close>
                <button
                  type="submit"
                  className="category-form__btn category-form__btn--primary"
                >
                  {editingCategory ? 'Update' : 'Create'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      {/* Delete Confirmation Dialog */}
      <Dialog.Root
        open={isDeleteDialogOpen}
        onOpenChange={setIsDeleteDialogOpen}
      >
        <Dialog.Portal>
          <Dialog.Overlay className="category-dialog__overlay" />
          <Dialog.Content className="category-dialog__content category-dialog__content--small">
            <Dialog.Title className="category-dialog__title">
              Delete Category?
            </Dialog.Title>
            <Dialog.Description className="category-dialog__description">
              Are you sure you want to delete "{categoryToDelete?.name}"? This
              action cannot be undone.
            </Dialog.Description>

            <div className="category-form__actions">
              <Dialog.Close asChild>
                <button
                  type="button"
                  className="category-form__btn category-form__btn--secondary"
                >
                  Cancel
                </button>
              </Dialog.Close>
              <button
                type="button"
                className="category-form__btn category-form__btn--danger"
                onClick={handleDeleteConfirm}
              >
                Delete
              </button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      {/* Alert Dialog for Success/Error Messages */}
      <AlertDialog.Root
        open={alertDialog.isOpen}
        onOpenChange={(isOpen: boolean) =>
          setAlertDialog({ ...alertDialog, isOpen })
        }
      >
        <AlertDialog.Portal>
          <AlertDialog.Overlay className="category-dialog__overlay" />
          <AlertDialog.Content className="category-dialog__content category-dialog__content--small">
            <AlertDialog.Title className="category-dialog__title">
              {alertDialog.title}
            </AlertDialog.Title>
            <AlertDialog.Description className="category-dialog__description">
              {alertDialog.description}
            </AlertDialog.Description>

            <div className="category-form__actions">
              <AlertDialog.Action asChild>
                <button
                  type="button"
                  className={`category-form__btn ${
                    alertDialog.variant === 'error'
                      ? 'category-form__btn--danger'
                      : 'category-form__btn--primary'
                  }`}
                >
                  OK
                </button>
              </AlertDialog.Action>
            </div>
          </AlertDialog.Content>
        </AlertDialog.Portal>
      </AlertDialog.Root>
    </div>
  );
}
