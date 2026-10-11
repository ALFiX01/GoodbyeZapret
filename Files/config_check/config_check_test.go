package main

import (
	"crypto/tls"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestDetailedReportRejectsServerErrorAndRecordsBody(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/bad" {
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		w.Write([]byte(strings.Repeat("x", 1024)))
	}))
	defer srv.Close()

	checker := NewChecker("", false, "auto")
	ok := checker.CheckDetailed(srv.URL + "/good")
	bad := checker.CheckDetailed(srv.URL + "/bad")
	if !ok.ok || ok.statusCode != 200 || ok.downloaded < 512 || ok.elapsed <= 0 {
		t.Fatalf("good result: %+v", ok)
	}
	if bad.ok || bad.reason != "HTTP_500" || bad.statusCode != 500 {
		t.Fatalf("bad result: %+v", bad)
	}

	path := filepath.Join(t.TempDir(), "report.txt")
	if err := writeReport(path, []domainResult{ok, bad}, 1, 2); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), "SUMMARY|1|2") || !strings.Contains(string(data), "HTTP_500") {
		t.Fatalf("report: %s", data)
	}
}

func TestTLSVersionDiagnosis(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(strings.Repeat("x", 65536)))
	}))
	defer srv.Close()
	srv.TLS.MinVersion = tls.VersionTLS12
	srv.TLS.MaxVersion = tls.VersionTLS12

	ok := diagnoseOnce(srv.URL, tls.VersionTLS12)
	if !ok.ok || ok.downloaded < 65536 || ok.tlsVersion != "TLS 1.2" {
		t.Fatalf("TLS 1.2: %+v", ok)
	}
	bad := diagnoseOnce(srv.URL, tls.VersionTLS13)
	if bad.ok {
		t.Fatalf("TLS 1.3 unexpectedly succeeded: %+v", bad)
	}
}

func TestUploadDiagnosisRecordsCompletedRequest(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		if r.Method != http.MethodPost || len(body) != 65536 {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}))
	defer srv.Close()
	r := diagnoseUploadOnce(srv.URL, tls.VersionTLS12)
	if !r.wroteRequest || !r.gotResponse || r.statusCode != http.StatusNoContent {
		t.Fatalf("upload result: %+v", r)
	}
}

func TestGoogleVideoCandidatesCountAsOneRequiredCheck(t *testing.T) {
	results := []domainResult{
		{domain: "rr1---sn-test.googlevideo.com", ok: false, reason: "TIMEOUT"},
		{domain: "rr2---sn-test.googlevideo.com", ok: true},
	}
	ok, total := summarizeGroups(buildResultGroups(results, false))
	if ok != 1 || total != 1 {
		t.Fatalf("summary: %d/%d", ok, total)
	}
}
