# Quick Reference: Modal Actions & Radix UI Dropdowns

## ✅ Completed

### 1. Add Transaction Modal
**File:** `features/accounts/components/AccountDetails.tsx`

**Usage:**
```tsx
// State
const [isAddTransactionModalOpen, setIsAddTransactionModalOpen] = useState(false);

// Handler
const handleAddTransaction = () => {
  setIsAddTransactionModalOpen(true);
};

// Render
<AddTransactionModal
  isOpen={isAddTransactionModalOpen}
  onClose={() => setIsAddTransactionModalOpen(false)}
  defaultAccountId={accountId}
/>
```

### 2. Radix UI Dropdown Menu
**Component:** `shared/components/DropdownSelect.tsx`

**Basic Usage:**
```tsx
<DropdownSelect
  label="Select Account"
  options={[
    { value: '1', label: 'Account 1' },
    { value: '2', label: 'Account 2' },
  ]}
  value={selectedValue}
  onChange={setValue}
  placeholder="Choose an account..."
  required
/>
```

**Advanced Features:**
- Error states: `error="Please select an option"`
- Helper text: `helperText="This is optional"`
- Disabled: `disabled={true}`
- Check marks on selected items
- Smooth animations
- Keyboard navigation

## 🔄 Pattern: Navigation → Modal

**Before (Bad UX):**
```tsx
const handleAction = () => {
  navigate({ to: '/other-page', search: { id } });
};
```

**After (Good UX):**
```tsx
const [isModalOpen, setIsModalOpen] = useState(false);

const handleAction = () => {
  setIsModalOpen(true);
};

// In JSX:
<YourModal
  isOpen={isModalOpen}
  onClose={() => setIsModalOpen(false)}
  defaultData={prefilledData}
/>
```

## 📦 Files Created

1. `AddTransactionModal.tsx` - Modal wrapper
2. `DropdownSelect.tsx` - Radix UI dropdown component
3. `DropdownSelect.css` - Dropdown styling

## 🎯 Next Actions to Implement

### Similar Modal Patterns Needed:
1. **Transfer Money Modal** (AccountDetails)
2. **Edit Budget Modal** (Budgets page)
3. **Add Goal Modal** (Goals page)

### More Dropdowns to Convert:
Check for remaining `<select>` elements in:
- Settings page (already uses Radix UI Select - different component)
- Any other forms with native selects

## 🚀 Quick Test Commands

```bash
# Run dev server
npm run dev

# Check TypeScript
npm run typecheck

# Run linter
npm run lint

# Generate routes
pnpm generate-routes
```

## 📱 Test Checklist

**Modal:**
- [ ] Opens on click
- [ ] Closes with X button
- [ ] Closes with Escape key
- [ ] Closes clicking outside
- [ ] Form submits correctly
- [ ] Pre-fills data properly

**Dropdown:**
- [ ] Opens/closes smoothly
- [ ] Shows selected value
- [ ] Keyboard navigation works
- [ ] Shows error states
- [ ] Mobile friendly
- [ ] Accessible

## 🎨 Styling Variables

**Used in DropdownSelect.css:**
```css
--color-background
--color-border
--color-text-primary
--color-text-secondary
--color-primary
--color-danger
--color-success
--color-background-hover
--shadow-sm
```

## 🔗 Related Files

- `features/transactions/components/AddTransactionForm.tsx` - The form shown in modal
- `features/accounts/components/AccountActions.tsx` - Quick action buttons
- `shared/components/CategorySelect/CategorySelect.tsx` - Uses DropdownSelect
- `features/transactions/components/QuickTransactionEntry.tsx` - Uses inline dropdowns

## 💡 Pro Tips

1. **Always pre-fill data in modals** - Better UX than empty forms
2. **Use descriptive trigger labels** - "Add Transaction" not "Add"
3. **Show success feedback** - Toast notification after modal closes
4. **Keep modals focused** - One clear action per modal
5. **Keyboard shortcuts** - Consider adding hotkeys for power users

## 🐛 Common Issues

**Modal doesn't open:**
- Check state is initialized correctly
- Verify `isOpen` prop is passed
- Check parent component isn't blocking

**Dropdown not showing options:**
- Verify options array has items
- Check Portal is rendering
- Look for z-index issues

**Dropdown selection not working:**
- Ensure `onChange` updates state
- Check value format matches option values
- Verify controlled component pattern

## 📚 Documentation

Full details: `docs/add-transaction-modal-radix-migration.md`
