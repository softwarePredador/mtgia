export type ManaColor = "W" | "U" | "B" | "R" | "G" | "C";

export type ManaCurvePoint = {
  label: string;
  value: number;
};

export type BreakdownItem = {
  label: string;
  value: number;
};

export type SwapRecommendation = {
  risk: "low" | "medium" | "high";
};
