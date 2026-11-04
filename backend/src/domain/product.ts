export type Product = {
  id: number;
  title: string;
  description: string;
  category: string;
  price: {
    amount: string;
    currency: "USD";
  };
  imageUrl: string;
  rating: {
    rate: number;
    count: number;
  };
};
