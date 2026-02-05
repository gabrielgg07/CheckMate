package main

import (
    "fmt"
    "os"

    "github.com/sideshow/apns2"
    "github.com/sideshow/apns2/token"
    "github.com/sideshow/apns2/payload"


)

func main() {
    // args: deviceToken type title body
    if len(os.Args) < 5 {
        fmt.Println("usage: ./apns_sender <deviceToken> <type> <title> <body>")
        return
    }

    deviceToken := os.Args[1]
    notifType := os.Args[2]
    title := os.Args[3]
    body := os.Args[4]

    authKey, err := token.AuthKeyFromFile("AuthKey_475XB44R37.p8")
    if err != nil {
        fmt.Println("Failed to load AuthKey:", err)
        return
    }

    tk := &token.Token{
        AuthKey: authKey,
        KeyID:   "475XB44R37",
        TeamID:  "Z4LS6UY7MC",
    }

    client := apns2.NewTokenClient(tk).Development()

    var pl *payload.Payload
	var pl2 *payload.Payload


    // SWITCH between silent and visible notifications:
    switch notifType {

    // ====================
    // 🔇 SILENT BACKGROUND PUSH (no alert)
    // ====================
    case "lock_silent", "unlock_silent", "extend_silent", "sync":
        //pl = payload.NewPayload().ContentAvailable()
		//b, _ := pl.MarshalJSON()
		//fmt.Println("DEBUG PAYLOAD:", string(b))
		fmt.Println("NOTIF TYPE:", string(notifType))
		fmt.Printf("RAW notifType bytes: %q\n", notifType)
		fmt.Println("LEN:", len(notifType))

        switch notifType {
			case "lock_silent":
				pl = payload.NewPayload().
					ContentAvailable().
					Custom("action", "lock_now")

			case "unlock_silent":
				pl = payload.NewPayload().
					ContentAvailable().
					Custom("action", "unlock_now")
					b, _ := pl.MarshalJSON()
					fmt.Println("DEBUG PAYLOAD:", string(b))
			case "extend_silent":
				pl = payload.NewPayload().
					ContentAvailable().
					Custom("action", "extend_time").
					Custom("minutes", 30)

			case "sync":
				pl = payload.NewPayload().
					ContentAvailable().
					Custom("action", "sync_status")

        }

    // ====================
    // 🔔 NORMAL VISIBLE NOTIFICATION
    // ====================
    case "lock", "unlock", "alert":
        pl = payload.NewPayload().
            AlertTitle(title).
            AlertBody(body).
            Sound("default")

        switch notifType {
        case "lock":
            pl.Custom("action", "lock_now")
			pl2 = payload.NewPayload().
				ContentAvailable().
				Custom("action", "lock_now")

        case "unlock":
            pl.Custom("action", "unlock_now")
			pl2 = payload.NewPayload().
				ContentAvailable().
				Custom("action", "unlock_now")
        }
		n2 := &apns2.Notification{
			DeviceToken: deviceToken,
			Topic:       "Inc3110.ScreenControl",
			Payload:     pl2,
			PushType:    apns2.PushTypeBackground,   // <— REQUIRED
			Priority:    apns2.PriorityLow,         // <— REQUIRED for silent push
		}
		res2, err2 := client.Push(n2)
		fmt.Println("Status:", res2.StatusCode)
		fmt.Println("Reason:", res2.Reason)
		if err2 != nil {
			fmt.Println("Push error:", err2)
			return
		}
		n := &apns2.Notification{
			DeviceToken: deviceToken,
			Topic:       "Inc3110.ScreenControl",
			Payload:     pl,
			PushType:    apns2.PushTypeAlert,   // <— REQUIRED
			Priority:    apns2.PriorityHigh,          // <— REQUIRED for silent push
		}
		res, err := client.Push(n)
		fmt.Println("Status:", res.StatusCode)
		fmt.Println("Reason:", res.Reason)
		if err != nil {
			fmt.Println("Push error:", err)
			return
		}
		return
    default:
        fmt.Println("Unknown notif type:", notifType)
        return
    }

    n := &apns2.Notification{
		DeviceToken: deviceToken,
		Topic:       "Inc3110.ScreenControl",
		Payload:     pl,
		PushType:    apns2.PushTypeBackground,   // <— REQUIRED
		Priority:    apns2.PriorityLow,          // <— REQUIRED for silent push
	}

	fmt.Println("payload final: ", n)
    res, err := client.Push(n)
	fmt.Println("Status:", res.StatusCode)
    fmt.Println("Reason:", res.Reason)
    if err != nil {
        fmt.Println("Push error:", err)
        return
    }

    fmt.Println("Status:", res.StatusCode)
    fmt.Println("Reason:", res.Reason)
}
