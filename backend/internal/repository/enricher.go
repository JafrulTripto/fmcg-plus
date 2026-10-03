package repository

import (
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"time"
)

type openFoodFactsResponse struct {
	Status  int `json:"status"` // 1 = found, 0 = not found
	Product struct {
		ProductName   string `json:"product_name"`
		ProductNameEn string `json:"product_name_en"`
		GenericName   string `json:"generic_name"`
		Brands        string `json:"brands"`
		Categories    string `json:"categories"`
		Quantity      string `json:"quantity"`
		ImageFrontURL string `json:"image_front_url"`
		ImageURL      string `json:"image_url"`
	} `json:"product"`
}

type EnrichedProductData struct {
	Barcode     string
	ProductName string
	Brand       string
	Category    string
	PackSize    string
	Unit        string
	ImageURL    string
	SKU         string
}

type EnrichmentService struct {
	httpClient *http.Client
}

func NewEnrichmentService() *EnrichmentService {
	return &EnrichmentService{
		httpClient: &http.Client{
			Timeout: 2500 * time.Millisecond,
		},
	}
}

// FetchProductFromInternet queries Open Food Facts and sister databases
func (s *EnrichmentService) FetchProductFromInternet(barcode string) (*EnrichedProductData, error) {
	barcode = strings.TrimSpace(barcode)
	if len(barcode) < 6 {
		return nil, fmt.Errorf("barcode too short")
	}

	// 1. Query Open Food Facts API (Food, beverages, groceries)
	offURL := fmt.Sprintf("https://world.openfoodfacts.org/api/v2/product/%s.json", barcode)
	data, err := s.fetchFromURL(offURL, barcode)
	if err == nil && data != nil {
		return data, nil
	}

	// 2. Query Open Beauty Facts API (Personal care, cosmetics, soaps, shampoo)
	obfURL := fmt.Sprintf("https://world.openbeautyfacts.org/api/v2/product/%s.json", barcode)
	data, err = s.fetchFromURL(obfURL, barcode)
	if err == nil && data != nil {
		if data.Category == "Food" || data.Category == "" {
			data.Category = "Personal Care"
		}
		return data, nil
	}

	// 3. Query Open Products Facts API (Household, stationery, other products)
	opfURL := fmt.Sprintf("https://world.openproductsfacts.org/api/v2/product/%s.json", barcode)
	data, err = s.fetchFromURL(opfURL, barcode)
	if err == nil && data != nil {
		if data.Category == "Food" || data.Category == "" {
			data.Category = "Household"
		}
		return data, nil
	}

	return nil, fmt.Errorf("product not found in online catalogs for barcode: %s", barcode)
}

func (s *EnrichmentService) fetchFromURL(url, barcode string) (*EnrichedProductData, error) {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "FMCGPlus-RetailPOS/2.5 (dev@fmcgplus.com.bd)")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP status %d", resp.StatusCode)
	}

	var raw openFoodFactsResponse
	if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
		return nil, err
	}

	if raw.Status != 1 {
		return nil, fmt.Errorf("item not found (status %d)", raw.Status)
	}

	p := raw.Product
	name := strings.TrimSpace(p.ProductName)
	if name == "" {
		name = strings.TrimSpace(p.ProductNameEn)
	}
	if name == "" {
		name = strings.TrimSpace(p.GenericName)
	}
	if name == "" {
		return nil, fmt.Errorf("no valid product name found in response")
	}

	img := p.ImageFrontURL
	if img == "" {
		img = p.ImageURL
	}

	brand := strings.TrimSpace(p.Brands)
	if commaIdx := strings.Index(brand, ","); commaIdx != -1 {
		brand = strings.TrimSpace(brand[:commaIdx])
	}

	category := deriveCategory(p.Categories, name)
	packSize, unit := derivePackSizeAndUnit(p.Quantity, name)

	catCode := "GEN"
	if len(category) >= 3 {
		catCode = strings.ToUpper(category[:3])
	}
	skuSuffix := barcode
	if len(barcode) >= 4 {
		skuSuffix = barcode[len(barcode)-4:]
	}
	sku := fmt.Sprintf("SKU-%s-%s", catCode, skuSuffix)

	return &EnrichedProductData{
		Barcode:     barcode,
		ProductName: name,
		Brand:       brand,
		Category:    category,
		PackSize:    packSize,
		Unit:        unit,
		ImageURL:    img,
		SKU:         sku,
	}, nil
}

func deriveCategory(categories, productName string) string {
	combined := strings.ToLower(categories + " " + productName)
	switch {
	case strings.Contains(combined, "beverage") || strings.Contains(combined, "drink") || strings.Contains(combined, "soda") || strings.Contains(combined, "juice") || strings.Contains(combined, "tea") || strings.Contains(combined, "coffee") || strings.Contains(combined, "water") || strings.Contains(combined, "cola"):
		return "Beverages"
	case strings.Contains(combined, "soap") || strings.Contains(combined, "shampoo") || strings.Contains(combined, "toothpaste") || strings.Contains(combined, "skin") || strings.Contains(combined, "hair") || strings.Contains(combined, "beauty") || strings.Contains(combined, "hygiene") || strings.Contains(combined, "cream") || strings.Contains(combined, "lotion"):
		return "Personal Care"
	case strings.Contains(combined, "detergent") || strings.Contains(combined, "cleaner") || strings.Contains(combined, "dish") || strings.Contains(combined, "wash") || strings.Contains(combined, "mosquito") || strings.Contains(combined, "air freshener") || strings.Contains(combined, "tissue"):
		return "Household"
	case strings.Contains(combined, "baby") || strings.Contains(combined, "diaper") || strings.Contains(combined, "infant") || strings.Contains(combined, "nappy"):
		return "Baby Products"
	default:
		return "Food"
	}
}

func derivePackSizeAndUnit(quantity, productName string) (string, string) {
	str := strings.TrimSpace(quantity)
	if str == "" {
		str = strings.TrimSpace(productName)
	}

	re := regexp.MustCompile(`(?i)(\d+(?:\.\d+)?)\s*(ml|l|ltr|liter|litres|gm?|kg|pcs?|pieces?|pack)`)
	match := re.FindStringSubmatch(str)
	if len(match) == 3 {
		val := match[1]
		unit := strings.ToLower(match[2])
		switch unit {
		case "gm", "g":
			return fmt.Sprintf("%s g", val), "g"
		case "kg":
			return fmt.Sprintf("%s kg", val), "kg"
		case "ml":
			return fmt.Sprintf("%s ml", val), "ml"
		case "l", "ltr", "liter", "litres":
			return fmt.Sprintf("%s L", val), "L"
		case "pcs", "pc", "piece", "pieces":
			return fmt.Sprintf("%s pcs", val), "pcs"
		}
	}
	if quantity != "" {
		return quantity, "pcs"
	}
	return "1 pcs", "pcs"
}
