package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
)

type PreviewResponse struct {
	CardID              string              `json:"cardId"`
	Profile             map[string]string   `json:"profile"`
	DigitalBusinessCard map[string]string   `json:"digitalBusinessCard"`
	Business            map[string]string   `json:"business"`
	LicenseInfo         map[string]string   `json:"licenseInfo"`
	BankAccounts        []map[string]string `json:"bankAccounts"`
	Address             map[string]string   `json:"address"`
	Documents           []map[string]string `json:"documents"`
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	mux.HandleFunc("/api/cards/", cardHandler)

	addr := envOrDefault("ADDR", ":8080")
	log.Printf("backend listening on %s", addr)
	if err := http.ListenAndServe(addr, withCORS(mux)); err != nil {
		log.Fatal(err)
	}
}

func cardHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	cardID := strings.TrimPrefix(r.URL.Path, "/api/cards/")
	if cardID == "" || strings.Contains(cardID, "/") {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid cardId"})
		return
	}

	resp, err := fetchAndNormalizeCard(cardID)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func fetchAndNormalizeCard(cardID string) (PreviewResponse, error) {
	baseURL := strings.TrimRight(envOrDefault("PB_BASE_URL", "https://cropzcard.pockethost.io"), "/")
	collection := envOrDefault("PB_CARDS_COLLECTION", "cards")
	token := strings.TrimSpace(os.Getenv("PB_AUTH_TOKEN"))

	endpoint := fmt.Sprintf("%s/api/collections/%s/records/%s", baseURL, url.PathEscape(collection), url.PathEscape(cardID))
	req, err := http.NewRequest(http.MethodGet, endpoint, nil)
	if err != nil {
		return PreviewResponse{}, fmt.Errorf("failed to create request: %w", err)
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	req.Header.Set("Accept", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return PreviewResponse{}, fmt.Errorf("pocketbase request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return PreviewResponse{}, fmt.Errorf("failed reading pocketbase response: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return PreviewResponse{}, fmt.Errorf("pocketbase returned %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	var record map[string]any
	if err := json.Unmarshal(body, &record); err != nil {
		return PreviewResponse{}, fmt.Errorf("invalid pocketbase JSON: %w", err)
	}

	payload, err := extractPayload(record)
	if err != nil {
		return PreviewResponse{}, err
	}
	return normalizePayload(cardID, payload), nil
}

func extractPayload(record map[string]any) (map[string]any, error) {
	value, ok := record["payload_json"]
	if !ok || value == nil {
		return nil, fmt.Errorf("cards record missing payload_json")
	}
	switch raw := value.(type) {
	case map[string]any:
		return raw, nil
	case string:
		var decoded map[string]any
		if err := json.Unmarshal([]byte(raw), &decoded); err != nil {
			return nil, fmt.Errorf("payload_json string is not valid JSON: %w", err)
		}
		return decoded, nil
	default:
		return nil, fmt.Errorf("unsupported payload_json type")
	}
}

func normalizePayload(cardID string, payload map[string]any) PreviewResponse {
	profile := getMap(payload, "profile")
	banks := getSlice(payload, "bank_infos")
	addresses := getSlice(payload, "addresses")
	documents := getSlice(payload, "documents")

	var bankItems []map[string]string
	for _, row := range banks {
		bank := mapToStringMap(row)
		if len(bank) == 0 {
			continue
		}
		bankItems = append(bankItems, map[string]string{
			"bankName":      bank["bank_name"],
			"accountNumber": bank["account_no"],
			"ifsc":          bank["ifsc_code"],
			"branch":        bank["branch"],
			"holderName":    bank["account_holder_name"],
			"accountType":   bank["account_type"],
		})
	}

	address := map[string]string{}
	if len(addresses) > 0 {
		first := mapToStringMap(addresses[0])
		address = map[string]string{
			"type":     first["address_type"],
			"line1":    first["address1"],
			"line2":    first["address2"],
			"line3":    first["address3"],
			"city":     first["city"],
			"district": first["district"],
			"state":    first["state"],
			"pincode":  first["pincode"],
		}
	}

	var docItems []map[string]string
	for _, row := range documents {
		doc := mapToStringMap(row)
		if len(doc) == 0 {
			continue
		}
		label := str(doc["label"])
		fileName := str(doc["file_name"])
		base64Data := strings.TrimSpace(doc["base64_data"])
		if label == "" || fileName == "" || base64Data == "" {
			continue
		}
		mimeType := str(doc["mime_type"])
		if mimeType == "" {
			mimeType = mimeTypeForFileName(fileName)
		}
		docItems = append(docItems, map[string]string{
			"label":       label,
			"fileName":    fileName,
			"mimeType":    mimeType,
			"downloadUrl": "data:" + mimeType + ";base64," + base64Data,
		})
	}

	return PreviewResponse{
		CardID: cardID,
		Profile: map[string]string{
			"name":      str(profile["firm_name"]),
			"role":      "Cropz User",
			"phone":     str(profile["mobile"]),
			"email":     str(profile["email"]),
			"avatarUrl": str(profile["profile_picture"]),
		},
		DigitalBusinessCard: map[string]string{
			"firmName":  str(profile["firm_name"]),
			"ownerName": str(profile["owner_name"]),
			"whatsapp":  str(profile["whatsapp"]),
			"upiId":     str(profile["upi_id"]),
			"transport": str(profile["transport"]),
			"companies": str(profile["companies"]),
			"recordId":  cardID,
		},
		Business: map[string]string{
			"businessName": str(profile["firm_name"]),
			"ownerName":    str(profile["owner_name"]),
			"mobile":       str(profile["mobile"]),
			"gst":          str(profile["gst_no"]),
		},
		LicenseInfo: map[string]string{
			"slNo":               str(profile["sl_no"]),
			"slExpiryDate":       str(profile["sl_expiry_date"]),
			"plNo":               str(profile["pl_no"]),
			"retailFlNo":         str(profile["retail_fl_no"]),
			"retailFlExpiryDate": str(profile["retail_fl_expiry_date"]),
			"wsFlNo":             str(profile["ws_fl_no"]),
			"wsFlExpiryDate":     str(profile["ws_fl_expiry_date"]),
			"fmsRetailId":        str(profile["fms_retail_id"]),
			"fmsWsId":            str(profile["fms_ws_id"]),
		},
		BankAccounts: bankItems,
		Address:      address,
		Documents:    docItems,
	}
}

func getMap(root map[string]any, key string) map[string]any {
	if value, ok := root[key].(map[string]any); ok {
		return value
	}
	return map[string]any{}
}

func getSlice(root map[string]any, key string) []any {
	if value, ok := root[key].([]any); ok {
		return value
	}
	return []any{}
}

func mapToStringMap(value any) map[string]string {
	row, ok := value.(map[string]any)
	if !ok {
		return map[string]string{}
	}
	out := make(map[string]string, len(row))
	for k, v := range row {
		out[k] = str(v)
	}
	return out
}

func str(value any) string {
	if value == nil {
		return ""
	}
	return strings.TrimSpace(fmt.Sprint(value))
}

func mimeTypeForFileName(fileName string) string {
	switch strings.ToLower(filepath.Ext(fileName)) {
	case ".pdf":
		return "application/pdf"
	case ".png":
		return "image/png"
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".webp":
		return "image/webp"
	default:
		return "application/octet-stream"
	}
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func envOrDefault(k, fallback string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return fallback
}
