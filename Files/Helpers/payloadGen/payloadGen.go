// by Ori
package main

import (
	"context"
	"crypto/tls"
	"encoding/hex"
	"flag"
	"fmt"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	uquic "github.com/refraction-networking/uquic"
	uhttp3 "github.com/refraction-networking/uquic/http3"
	utls "github.com/refraction-networking/utls"
	"golang.org/x/net/http2"
)

const version = "0.9.1"

var (
	tcpListenerReady   = make(chan bool)
	udpListenerReady   = make(chan bool)
	tcpListenerQuitted = make(chan bool)
	udpListenerQuitted = make(chan bool)

	browsers_TLS_CH       = browsers_TLS_CH_type{}
	browsers_QUIC_Initial = browsers_QUIC_Initial_type{}

	flag_BrowserTLSCH *string
	flag_BrowserQUIC  *string
	flag_CropAt       *int
	flag_SNI          *string

	loopbackPort = 4343

	defaultSNI = "fonts.google.com"
)

type browsers_TLS_CH_type []struct {
	name            string
	utls_pointer    *utls.ClientHelloID
	additional_info string
}

func (b *browsers_TLS_CH_type) add(_name string, _ptr *utls.ClientHelloID, _info string) {
	*b = append(*b, struct {
		name            string
		utls_pointer    *utls.ClientHelloID
		additional_info string
	}{name: _name, utls_pointer: _ptr, additional_info: _info})
}

func (b *browsers_TLS_CH_type) getID(_name string) int {
	for n, each := range *b {
		if each.name == _name {
			return n
		}
	}
	return -1
}

type browsers_QUIC_Initial_type []struct {
	name            string
	uquic_pointer   *uquic.QUICID
	additional_info string
}

func (b *browsers_QUIC_Initial_type) add(_name string, _ptr *uquic.QUICID, _info string) {
	*b = append(*b, struct {
		name            string
		uquic_pointer   *uquic.QUICID
		additional_info string
	}{name: _name, uquic_pointer: _ptr, additional_info: _info})
}

func (b *browsers_QUIC_Initial_type) getID(_name string) int {
	for n, each := range *b {
		if each.name == _name {
			return n
		}
	}
	return -1
}

func init() {
	browsers_TLS_CH.add("Firefox 120", &utls.HelloFirefox_120, "")
	browsers_TLS_CH.add("Chrome 102", &utls.HelloChrome_102, "")
	browsers_TLS_CH.add("Chrome 106 (Shuffle)", &utls.HelloChrome_106_Shuffle, "Chrome added TLS extension shuffler starting this version")
	browsers_TLS_CH.add("Chrome 112 (PSK, Shuffle)", &utls.HelloChrome_112_PSK_Shuf, "Chrome added Pre-shared Key extension starting this version, but uTLS doesn't have full support for it")
	browsers_TLS_CH.add("Chrome 115 (PQ)", &utls.HelloChrome_115_PQ, "Chrome added Post-Quantum Key Agreement extension starting this version, but uTLS doesn't have full support for it")
	browsers_TLS_CH.add("Chrome 120 (ECH)", &utls.HelloChrome_120, "Chrome added Encrypted ClientHello starting this version")
	browsers_TLS_CH.add("Chrome 120 (ECH, PQ)", &utls.HelloChrome_120_PQ, "")
	browsers_TLS_CH.add("Chrome 131 (ML-KEM curve)", &utls.HelloChrome_131, "Chrome added Module-Lattice Key Encapsulation Mechanism a.k.a. Kyber starting this version")
	browsers_TLS_CH.add("Android 11", &utls.HelloAndroid_11_OkHttp, "")
	browsers_TLS_CH.add("Edge 85", &utls.HelloEdge_85, "")
	browsers_TLS_CH.add("Edge 106", &utls.HelloEdge_106, "Edge 106 seems to be incompatible with uTLS library, according to them")
	browsers_TLS_CH.add("Safari 16.0", &utls.HelloSafari_16_0, "")
	browsers_TLS_CH.add("Random ALPN", &utls.HelloRandomizedALPN, "Randomize fields, use Application-Layer Protocol Negotiation TLS extension")
	browsers_TLS_CH.add("Random", &utls.HelloRandomizedNoALPN, "Randomize fields")

	browsers_QUIC_Initial.add("Firefox 116 (A)", &uquic.QUICFirefox_116A, "Destination Connection ID length = 8 bytes")
	browsers_QUIC_Initial.add("Firefox 116 (B)", &uquic.QUICFirefox_116B, "Destination Connection ID length = 9 bytes")
	browsers_QUIC_Initial.add("Firefox 116 (C)", &uquic.QUICFirefox_116C, "Destination Connection ID length = 15 bytes")
	browsers_QUIC_Initial.add("Chrome 115 (IPv4)", &uquic.QUICChrome_115_IPv4, "")
	browsers_QUIC_Initial.add("Chrome 115 (IPv6)", &uquic.QUICChrome_115_IPv6, "")

	flag_BrowserTLSCH = flag.String("ch", "skip", "Which browser to mimic for TLS ClientHello payload (skip when omitted)")
	flag_BrowserQUIC = flag.String("qi", "skip", "Which browser to mimic for QUIC Initial payload (skip when omitted)")
	flag_CropAt = flag.Int("crop", -1, "At which byte to crop binary (not cropped when omitted/negative)")
	flag_SNI = flag.String("sni", defaultSNI, "SNI to use for payload (default when omitted)")

	flag.Usage = func() {
		fmt.Printf("\n\tPayload Generator v%s by Ori\n\n", version)

		flag.VisitAll(func(f *flag.Flag) {
			fmt.Printf("\t-%s\t- %s (default: %s)\n", f.Name, f.Usage, f.DefValue)
		})
		fmt.Printf("\n\tBrowsers for TLS ClientHello:\n\n")
		for _, each := range browsers_TLS_CH {
			if each.additional_info != "" {
				fmt.Printf("\t\"%s\" (%s)\n", each.name, each.additional_info)
			} else {
				fmt.Printf("\t\"%s\"\n", each.name)
			}
		}
		fmt.Printf("\n\tBrowsers for QUIC Initial:\n\n")
		for _, each := range browsers_QUIC_Initial {
			if each.additional_info != "" {
				fmt.Printf("\t\"%s\" (%s)\n", each.name, each.additional_info)
			} else {
				fmt.Printf("\t\"%s\"\n", each.name)
			}
		}
		fmt.Printf("\n\tExample: %s -ch \"%s\" -sni %s\n", os.Args[0], browsers_TLS_CH[7].name, "example.com")
	}

	flag.Parse()
}

func main() {
	fmt.Printf("\nPayload Generator v%s by Ori\n\n-----------------\n\n", version)

	var bTLS_id, bQUIC_id int = -1, -1
	if flag.NFlag() > 0 {
		if *flag_BrowserTLSCH != "skip" {
			bTLS_id = browsers_TLS_CH.getID(*flag_BrowserTLSCH)
			if bTLS_id < 0 {
				check(fmt.Errorf("unknown browser: %s", *flag_BrowserTLSCH))
			}
		}
		if *flag_BrowserQUIC != "skip" {
			bQUIC_id = browsers_QUIC_Initial.getID(*flag_BrowserQUIC)
			if bQUIC_id < 0 {
				check(fmt.Errorf("unknown browser: %s", *flag_BrowserQUIC))
			}
		}
		if bTLS_id < 0 && bQUIC_id < 0 {
			check(fmt.Errorf("nothing to do"))
		}
	} else {
		bTLS_id = mimicBrowserTLS()
		fmt.Printf("\n-----------------\n\n")
		bQUIC_id = mimicBrowserQUIC()
		fmt.Printf("\n-----------------\n\n")
		if bTLS_id < 0 && bQUIC_id < 0 {
			check(fmt.Errorf("nothing to do"))
		}
		*flag_CropAt = selectCrop()
		fmt.Printf("\n-----------------\n\n")
		*flag_SNI = inputSNI()
		fmt.Printf("\n-----------------\n\n")
	}

	fmt.Printf("TLS CLientHello: %t\nQUIC Initial: %t\n", (bTLS_id >= 0), (bQUIC_id >= 0))
	if bTLS_id >= 0 {
		fmt.Printf("Browser for TLS ClientHello: %s\n", browsers_TLS_CH[bTLS_id].name)
	}
	if bQUIC_id >= 0 {
		fmt.Printf("Browser for QUIC Initial: %s\n", browsers_QUIC_Initial[bQUIC_id].name)
	}
	fmt.Printf("Crop at: %d\nSNI: %s\n\n-----------------\n\n", *flag_CropAt, *flag_SNI)

	if bTLS_id >= 0 {
		go listenTCP(*flag_CropAt, &bTLS_id)
		<-tcpListenerReady
		go sendRequestTLS(&bTLS_id)
		<-tcpListenerQuitted
		fmt.Printf("\n-----------------\n\n")
	}

	if bQUIC_id >= 0 {
		go listenUDP(*flag_CropAt, &bQUIC_id)
		<-udpListenerReady
		go sendRequestQUIC(&bQUIC_id)
		<-udpListenerQuitted
		fmt.Printf("\n-----------------\n\n")
	}

	if flag.NFlag() > 0 {
		fmt.Println("All done..")
	} else {
		fmt.Println("All done, press [ENTER] to exit..")
		fmt.Scanln()
	}
	os.Exit(0)
}

func selectCrop() int {
	for {
		fmt.Print("> At which byte to crop binary (leave empty to skip): ")
		var s string
		fmt.Scanln(&s)
		if s == "" {
			return -1
		}
		i, err := strconv.Atoi(s)
		if err != nil || i <= 0 || i >= 65534 {
			fmt.Printf("   ! Incorrect value !\n")
		} else {
			return i
		}
	}
}

func mimicBrowserTLS() int {
	fmt.Println("0. Do not create TLS ClientHello")
	for n, each := range browsers_TLS_CH {
		if each.additional_info != "" {
			fmt.Printf("%d. %s (%s)\n", n+1, each.name, each.additional_info)
		} else {
			fmt.Printf("%d. %s\n", n+1, each.name)
		}
	}
	for {
		fmt.Printf("\n> Which browser to mimic for TLS ClientHello (leave empty for default [%s]): ", browsers_TLS_CH[0].name)
		var s string
		fmt.Scanln(&s)
		if s == "" {
			return 0
		}
		i, err := strconv.Atoi(s)
		if err != nil || i < 0 || i > len(browsers_TLS_CH) {
			fmt.Printf("   ! Incorrect value !\n")
		} else {
			return (i - 1)
		}
	}
}

func mimicBrowserQUIC() int {
	fmt.Println("0. Do not create QUIC Initial")
	for n, each := range browsers_QUIC_Initial {
		if each.additional_info != "" {
			fmt.Printf("%d. %s (%s)\n", n+1, each.name, each.additional_info)
		} else {
			fmt.Printf("%d. %s\n", n+1, each.name)
		}
	}
	for {
		fmt.Printf("\n> Which browser to mimic for QUIC Initial (leave empty for default [%s]): ", browsers_QUIC_Initial[0].name)
		var s string
		fmt.Scanln(&s)
		if s == "" {
			return 0
		}
		i, err := strconv.Atoi(s)
		if err != nil || i < 0 || i > len(browsers_QUIC_Initial) {
			fmt.Printf("   ! Incorrect value !\n")
		} else {
			return (i - 1)
		}
	}
}

func inputSNI() string {
	var s string
	fmt.Printf("> Specify a SNI for payload (leave empty for default '%s'): ", *flag_SNI)
	fmt.Scanln(&s)
	if s != "" {
		return s
	}
	return *flag_SNI
}

func sendRequestTLS(browser_id *int) {

	// For some addresses like https://example.com/ http.Transport worked perfectly, while http2.Transport failing.
	// But for some others, like https://www.google.com/ it's vice versa. Dunno why, so gonna leave the code here.

	// tr := &http.Transport{}
	// tr.DialTLSContext = func(ctx context.Context, network string, addr string) (net.Conn, error) {

	// 	conn, err := net.Dial(network, addr)
	// 	if err != nil {
	// 		return nil, err
	// 	}

	// 	uconn := utls.UClient(conn, &utls.Config{
	// 		// InsecureSkipVerify: true,
	// 		NextProtos: []string{"h2", "http/1.1"},
	// 		ServerName:         sni,
	// 		MinVersion: utls.VersionTLS12,
	// 		MaxVersion: utls.VersionTLS13,
	// 	}, *ch)

	// 	err = uconn.SetTLSVers(utls.VersionTLS12, utls.VersionTLS13, uconn.Extensions)
	// 	if err != nil {
	// 		return nil, err
	// 	}

	// 	return uconn, nil
	// }

	tr := &http2.Transport{}
	tr.DialTLSContext = func(ctx context.Context, network string, addr string, cfg *tls.Config) (net.Conn, error) {

		conn, err := net.Dial(network, addr)
		if err != nil {
			return nil, err
		}

		uconn := utls.UClient(conn, &utls.Config{
			InsecureSkipVerify: true,
			// NextProtos:         cfg.NextProtos,
			NextProtos: []string{"h2", "http/1.1"},
			ServerName: *flag_SNI,
			MinVersion: utls.VersionTLS12,
			MaxVersion: utls.VersionTLS13,
		}, *browsers_TLS_CH[*browser_id].utls_pointer)

		err = uconn.SetTLSVers(utls.VersionTLS12, utls.VersionTLS13, uconn.Extensions)
		if err != nil {
			return nil, err
		}

		return uconn, nil
	}

	client := &http.Client{
		Transport: tr,
		Timeout:   1 * time.Second,
	}

	fmt.Printf("Sending TCP request\n\n")
	client.Get(fmt.Sprintf("https://localhost:%d", loopbackPort)) // ignoring an error here
	client.CloseIdleConnections()
}

func sendRequestQUIC(browser_id *int) {

	roundTripper := &uhttp3.RoundTripper{
		TLSClientConfig: &utls.Config{
			NextProtos:         []string{"h3"},
			InsecureSkipVerify: true,
			ServerName:         *flag_SNI,
			MinVersion:         tls.VersionTLS12,
		},
		QuicConfig: &uquic.Config{},
	}

	quicSpec, err := uquic.QUICID2Spec(*browsers_QUIC_Initial[*browser_id].uquic_pointer)
	check(err)

	uRoundTripper := uhttp3.GetURoundTripper(
		roundTripper,
		&quicSpec,
		nil,
	)
	defer uRoundTripper.Close()

	h3client := &http.Client{
		Timeout:   1 * time.Second,
		Transport: uRoundTripper,
	}

	fmt.Printf("Sending UDP request\n\n")

	h3client.Get(fmt.Sprintf("https://localhost:%d", loopbackPort)) // ignoring an error here
	h3client.CloseIdleConnections()
}

func listenTCP(cropAt int, browser_id *int) {
	tcpListener, err := net.Listen("tcp", fmt.Sprintf(":%d", loopbackPort))
	check(err)
	defer tcpListener.Close()

	fmt.Printf("TCP Listener ready\n\n")
	tcpListenerReady <- true

	buf := make([]byte, 65535)

	tcpConn, err := tcpListener.Accept()
	check(err)
	defer tcpConn.Close()

	n, err := tcpConn.Read(buf)
	check(err)

	if cropAt < 0 {
		buf = buf[:n]
	} else {
		buf = buf[:cropAt]
	}

	hexString := hex.EncodeToString(buf)
	fmt.Printf("Hex for TLS ClientHello: %s\n\n", hexString)

	saveToBinaryFile(buf, "TLS_ClientHello", browsers_TLS_CH[*browser_id].name)

	tcpListenerQuitted <- true
}

func listenUDP(cropAt int, browser_id *int) {

	udpConn, err := net.ListenUDP("udp", &net.UDPAddr{Port: loopbackPort})
	check(err)
	defer udpConn.Close()

	buf := make([]byte, 65535)

	fmt.Printf("UDP Listener ready\n\n")
	udpListenerReady <- true

	n, _, err := udpConn.ReadFromUDP(buf)
	check(err)

	if cropAt < 0 {
		buf = buf[:n]
	} else {
		buf = buf[:cropAt]
	}

	hexString := hex.EncodeToString(buf)
	fmt.Printf("Hex for QUIC Initial: %s\n\n", hexString)

	saveToBinaryFile(buf, "QUIC_Initial", browsers_QUIC_Initial[*browser_id].name)

	udpListenerQuitted <- true
}

func saveToBinaryFile(b []byte, marker string, browser string) {
	t := time.Now().Format("2006.01.02 15-04-05")

	// create a replacer to sanitize filename parts: replace spaces with underscores and remove brackets/parentheses
	replacer := strings.NewReplacer(
		" ", "_",
		"(", "",
		")", "",
		"[", "",
		"]", "",
	)

	sanitizedMarker := replacer.Replace(marker)
	sanitizedBrowser := replacer.Replace(browser)
	sanitizedSNI := replacer.Replace(*flag_SNI)
	sanitizedTime := replacer.Replace(t)

	filename := fmt.Sprintf("%s_%s_%s_%s.bin", sanitizedMarker, sanitizedBrowser, sanitizedSNI, sanitizedTime)

	err := os.WriteFile(filename, b, 0200)
	check(err)

	fmt.Printf("Saved %d bytes as %s\n", len(b), filename)
}

func check(err error) {
	switch err {
	case nil:
		return
	default:
		fmt.Println("ERROR:", err)
		fmt.Scanln()
		os.Exit(1)
	}
}
