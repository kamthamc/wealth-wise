/**
 * Firebase Service
 * Handles Firebase integration for caching stock prices and real-time sync
 */

import type { InvestmentPrice } from '@/core/types';

interface FirebaseConfig {
  apiKey: string;
  authDomain?: string;
  projectId?: string;
  storageBucket?: string;
  messagingSenderId?: string;
  appId?: string;
}

interface PriceCache {
  [symbol: string]: InvestmentPrice;
}

/**
 * Firebase Service Class
 * Manages price caching and real-time updates using Firebase Realtime Database
 */
class FirebaseService {
  private config: FirebaseConfig | null = null;
  private isInitialized = false;
  private priceCache: PriceCache = {};
  private readonly CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

  /**
   * Initialize Firebase with configuration
   */
  async initialize(config: FirebaseConfig): Promise<void> {
    if (this.isInitialized) {
      console.warn('Firebase already initialized');
      return;
    }

    this.config = config;
    this.isInitialized = true;

    console.log('Firebase initialized successfully');
  }

  /**
   * Check if Firebase is configured and initialized
   */
  isConfigured(): boolean {
    return this.isInitialized && this.config !== null;
  }

  /**
   * Get cached price for a symbol
   * Returns null if not cached or expired
   */
  async getCachedPrice(symbol: string): Promise<InvestmentPrice | null> {
    if (!this.isConfigured()) {
      return null;
    }

    try {
      // Check local cache first
      const cached = this.priceCache[symbol];
      if (cached && this.isCacheValid(cached)) {
        return cached;
      }

      // Fetch from Firebase
      // TODO: Replace with actual Firebase Realtime Database call
      const response = await this.fetchFromFirebase(`prices/${symbol}`);

      if (response) {
        const price: InvestmentPrice = {
          ...response,
          last_updated: new Date(response.last_updated),
        };

        // Update local cache
        this.priceCache[symbol] = price;
        return price;
      }

      return null;
    } catch (error) {
      console.error(`Error fetching cached price for ${symbol}:`, error);
      return null;
    }
  }

  /**
   * Get multiple cached prices in batch
   */
  async getCachedPrices(symbols: string[]): Promise<PriceCache> {
    if (!this.isConfigured()) {
      return {};
    }

    try {
      const prices: PriceCache = {};

      // Fetch all prices in parallel
      const results = await Promise.allSettled(
        symbols.map((symbol) => this.getCachedPrice(symbol))
      );

      results.forEach((result, index) => {
        const symbol = symbols[index];
        if (result.status === 'fulfilled' && result.value && symbol) {
          prices[symbol] = result.value;
        }
      });

      return prices;
    } catch (error) {
      console.error('Error fetching cached prices:', error);
      return {};
    }
  }

  /**
   * Update price in cache
   * Only updates if the price is newer or not cached
   */
  async updateCachedPrice(price: InvestmentPrice): Promise<void> {
    if (!this.isConfigured()) {
      console.warn('Firebase not configured, skipping price update');
      return;
    }

    try {
      // Check if we should update (only if newer or not cached)
      const cached = this.priceCache[price.symbol];
      const shouldUpdate =
        !cached || new Date(price.last_updated) > new Date(cached.last_updated);

      if (!shouldUpdate) {
        return;
      }

      // Update Firebase
      // TODO: Replace with actual Firebase Realtime Database call
      await this.saveToFirebase(`prices/${price.symbol}`, {
        ...price,
        last_updated: price.last_updated.toISOString(),
      });

      // Update local cache
      this.priceCache[price.symbol] = price;

      console.log(`Updated cached price for ${price.symbol}`);
    } catch (error) {
      console.error(`Error updating cached price for ${price.symbol}:`, error);
    }
  }

  /**
   * Update multiple prices in batch
   */
  async updateCachedPrices(prices: InvestmentPrice[]): Promise<void> {
    if (!this.isConfigured()) {
      console.warn('Firebase not configured, skipping batch price update');
      return;
    }

    try {
      // Update all prices in parallel
      await Promise.allSettled(
        prices.map((price) => this.updateCachedPrice(price))
      );

      console.log(`Updated ${prices.length} cached prices`);
    } catch (error) {
      console.error('Error updating cached prices:', error);
    }
  }

  /**
   * Fetch price from external API and update cache
   * This is called when local cache is expired or missing
   */
  async fetchAndCachePrice(
    symbol: string,
    exchange?: string
  ): Promise<InvestmentPrice | null> {
    try {
      // First check Firebase cache
      const cached = await this.getCachedPrice(symbol);
      if (cached && this.isCacheValid(cached)) {
        return cached;
      }

      // Fetch from external API (mock for now)
      const price = await this.fetchPriceFromAPI(symbol, exchange);

      if (price) {
        // Update Firebase cache
        await this.updateCachedPrice(price);
        return price;
      }

      return null;
    } catch (error) {
      console.error(`Error fetching and caching price for ${symbol}:`, error);
      return null;
    }
  }

  /**
   * Subscribe to real-time price updates
   * Returns unsubscribe function
   */
  subscribeToPriceUpdates(
    symbols: string[],
    callback: (prices: PriceCache) => void
  ): () => void {
    if (!this.isConfigured()) {
      console.warn('Firebase not configured, skipping subscription');
      return () => {};
    }

    // TODO: Implement actual Firebase real-time listener
    console.log('Subscribing to price updates for:', symbols);

    // Mock subscription - in real implementation, this would use Firebase onValue
    const interval = setInterval(async () => {
      const prices = await this.getCachedPrices(symbols);
      callback(prices);
    }, 30000); // Poll every 30 seconds

    // Return unsubscribe function
    return () => {
      clearInterval(interval);
      console.log('Unsubscribed from price updates');
    };
  }

  /**
   * Clear all cached prices
   */
  clearCache(): void {
    this.priceCache = {};
    console.log('Price cache cleared');
  }

  /**
   * Disconnect from Firebase
   */
  disconnect(): void {
    this.clearCache();
    this.isInitialized = false;
    this.config = null;
    console.log('Firebase disconnected');
  }

  /**
   * Private helper: Check if cached price is still valid
   */
  private isCacheValid(price: InvestmentPrice): boolean {
    const age = Date.now() - new Date(price.last_updated).getTime();
    return age < this.CACHE_TTL_MS;
  }

  /**
   * Private helper: Fetch data from Firebase
   * TODO: Replace with actual Firebase SDK calls
   */
  private async fetchFromFirebase(path: string): Promise<any> {
    // Mock implementation
    // In real implementation, use Firebase Realtime Database:
    // const snapshot = await get(ref(database, path));
    // return snapshot.val();

    console.log(`Fetching from Firebase: ${path}`);
    return null;
  }

  /**
   * Private helper: Save data to Firebase
   * TODO: Replace with actual Firebase SDK calls
   */
  private async saveToFirebase(path: string, data: any): Promise<void> {
    // Mock implementation
    // In real implementation, use Firebase Realtime Database:
    // await set(ref(database, path), data);

    console.log(`Saving to Firebase: ${path}`, data);
  }

  /**
   * Private helper: Fetch price from external API
   * TODO: Integrate with actual market data API (Alpha Vantage, Yahoo Finance, etc.)
   */
  private async fetchPriceFromAPI(
    symbol: string,
    exchange?: string
  ): Promise<InvestmentPrice | null> {
    // Mock implementation
    // In real implementation, call market data API

    console.log(
      `Fetching price from API: ${symbol} (${exchange || 'default'})`
    );

    // Return mock data
    return {
      symbol,
      price: Math.random() * 1000,
      currency: 'INR',
      exchange: exchange || 'NSE',
      last_updated: new Date(),
      source: 'mock_api',
    };
  }
}

// Export singleton instance
export const firebaseService = new FirebaseService();

// Export type for configuration
export type { FirebaseConfig };
