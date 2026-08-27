import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface CartItem {
  id: string;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;
  clearCart: () => void;
}

export const useCartStore = create<CartState>()(
  persist(
    (set) => ({
      items: [],
      addItem: (newItem) => set((state) => {
        const existingItem = state.items.find(item => item.id === newItem.id);
        if (existingItem) {
          return {
            items: state.items.map(item => 
              item.id === newItem.id 
                ? { ...item, quantity: item.quantity + newItem.quantity }
                : item
            )
          };
        }
        return { items: [...state.items, newItem] };
      }),
      removeItem: (id) => set((state) => ({
        items: state.items.filter(item => item.id !== id)
      })),
      clearCart: () => set({ items: [] }),
    }),
    {
      name: 'sora-guest-cart',
    }
  )
);
