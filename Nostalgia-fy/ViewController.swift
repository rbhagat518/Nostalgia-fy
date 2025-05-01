//
//  ViewController.swift
//  HelloSpotify
//
//  Created by Ram Bhagat  on 4/17/25.
//
import UIKit
import AuthenticationServices

struct SpotifyResponse: Codable {
    let items: [PlayedItem]
}

struct PlayedItem: Codable {
    let track: Track
    let playedAt: String

    enum CodingKeys: String, CodingKey {
        case track
        case playedAt = "played_at"
    }
}

struct Track: Codable {
    let name: String
    let artists: [Artist]
}

struct Artist: Codable {
    let name: String
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var playedItems: [PlayedItem] = []
    var selectedItem: PlayedItem?

    var verifier = ""
    let clientID = "f990c1701dea409685e8d415fb6f4151"
    let redirectURI = "nostalgia-fy://callback"
    var accessToken: String?

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }

    @IBAction func loginWithSpotify(_ sender: UIButton) {
        verifier = PKCE.generateCodeVerifier()
        let challenge = PKCE.codeChallenge(for: verifier)

        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/authorize"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: "user-read-recently-played")
        ]

        let authURL = components.url!
        print("AUTH URL: \(authURL.absoluteString)")

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "nostalgia-fy") { callbackURL, error in
            guard let callbackURL = callbackURL,
                  let code = self.extractCode(from: callbackURL) else {
                print("Auth failed:", error?.localizedDescription ?? "No error")
                return
            }

            self.exchangeCodeForToken(code: code)
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        session.start()
    }

    func extractCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return nil
        }
        return code
    }

    func exchangeCodeForToken(code: String) {
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        let body = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": verifier
        ]
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            do {
                let tokenData = try JSONDecoder().decode(TokenResponse.self, from: data)
                print("Access Token:", tokenData.access_token)
                DispatchQueue.main.async {
                    self.accessToken = tokenData.access_token
                }
            } catch {
                print("Token parse error:", error)
            }
        }.resume()
    }

    @IBAction func fetchTracksTapped(_ sender: UIButton) {
        let selectedDate = datePicker.date
        fetchRecentlyPlayed(for: selectedDate)
    }

    func fetchRecentlyPlayed(for date: Date) {
        guard let token = accessToken else {
            print("No access token yet.")
            return
        }

        let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played?limit=50")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("Failed to fetch tracks:", error?.localizedDescription ?? "unknown error")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SpotifyResponse.self, from: data)

                var calendar = Calendar.current
                calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                let selectedComponents = calendar.dateComponents([.year, .month, .day], from: date)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                formatter.timeZone = TimeZone(secondsFromGMT: 0)

                let filtered = decoded.items.filter { item in
                    guard let playedAt = formatter.date(from: item.playedAt) else {
                        return false
                    }
                    let itemComponents = calendar.dateComponents([.year, .month, .day], from: playedAt)
                    return itemComponents == selectedComponents
                }

                DispatchQueue.main.async {
                    self.playedItems = filtered
                    self.tableView.reloadData()
                }

            } catch {
                print("JSON parse error:", error)
            }
        }.resume()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let item = playedItems[indexPath.row]
        let track = item.track
        cell.textLabel?.text = track.name
        cell.detailTextLabel?.text = "by " + track.artists.map { $0.name }.joined(separator: ", ")
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItem = playedItems[indexPath.row]
        performSegue(withIdentifier: "ShowMontage", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMontage",
           let dest = segue.destination as? MontageViewController,
           let item = selectedItem {
            dest.track = item.track
            dest.playedAt = item.playedAt
        }
    }
}

extension ViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window!
    }
}

struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
}


/*
import UIKit
import AuthenticationServices

struct SpotifyResponse: Codable {
    let items: [PlayedItem]
}

struct PlayedItem: Codable {
    let track: Track
    let playedAt: String

    enum CodingKeys: String, CodingKey {
        case track
        case playedAt = "played_at"
    }
}


struct Track: Codable {
    let name: String
    let artists: [Artist]
}

struct Artist: Codable {
    let name: String
}




class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let track = tracks[indexPath.row]
        cell.textLabel?.text = track.name
        cell.detailTextLabel?.text = "by " + track.artists.map { $0.name }.joined(separator: ", ")
        return cell
    }
    
    var tracks: [Track] = []

    var verifier = ""
    let clientID = "f990c1701dea409685e8d415fb6f4151"
    let redirectURI = "nostalgia-fy://callback"
    var accessToken: String?
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func loginWithSpotify(_ sender: UIButton) {
        
        verifier = PKCE.generateCodeVerifier()
        let challenge = PKCE.codeChallenge(for: verifier)
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/authorize"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: "user-read-recently-played")
        ]

        let authURL = components.url!
        print("AUTH URL: \(authURL.absoluteString)")
        
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "nostalgia-fy") { callbackURL, error in
            guard let callbackURL = callbackURL,
                  let code = self.extractCode(from: callbackURL) else {
                print("Auth failed:", error?.localizedDescription ?? "No error")
                return
            }
            
            self.exchangeCodeForToken(code: code)
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        session.start()
    }
        func extractCode(from url: URL) -> String? {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                return nil
            }
            return code
        }
        
        func exchangeCodeForToken(code: String) {
            let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
            var request = URLRequest(url: tokenURL)
            request.httpMethod = "POST"
            let body = [
                "client_id": clientID,
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": redirectURI,
                "code_verifier": verifier
            ]
            request.httpBody = body
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
                .data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else { return }
                do {
                    let tokenData = try JSONDecoder().decode(TokenResponse.self, from: data)
                    print("Access Token:", tokenData.access_token)
                    DispatchQueue.main.async {
                        self.accessToken = tokenData.access_token
                        print("Access Token:", tokenData.access_token)
                    }
                    // ✅ You can now use `tokenData.access_token` to call Spotify APIs
                } catch {
                    print("Token parse error:", error)
                }
            }.resume()
            
        }
    var selectedTrack: Track?

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTrack = tracks[indexPath.row]
        performSegue(withIdentifier: "ShowMontage", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMontage",
           let dest = segue.destination as? MontageViewController,
           let track = selectedTrack {
            dest.track = track
        }
    }

    func fetchRecentlyPlayed(for date: Date) {
        guard let token = accessToken else {
            print("No access token yet.")
            return
        }

        let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played?limit=50")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("hello", date)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("Failed to fetch tracks:", error?.localizedDescription ?? "unknown error")
                return
            }

            do {
                print("hi from within the do statement")
                let decoded = try JSONDecoder().decode(SpotifyResponse.self, from: data)

                for item in decoded.items {
                    print("🎧 Track:", item.track.name)
                    print("📅 Played at (raw):", item.playedAt)
                }
                
                var calendar = Calendar.current
                //var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                let selectedComponents = calendar.dateComponents([.year, .month, .day], from: date)
                print("📍 Selected date:", selectedComponents)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                formatter.timeZone = TimeZone(secondsFromGMT: 0)  // Optional but good practice
                
                let filteredTracks = decoded.items.filter { item in
                    print("hi from within filter")
                    print(item.playedAt)
                    guard let playedAt = formatter.date(from: item.playedAt) else {
                        print("returns false")
                        return false
                    }
                    let itemComponents = calendar.dateComponents([.year, .month, .day], from: playedAt)
                    print("🧪 Comparing:", itemComponents, "vs", selectedComponents)
                    return itemComponents == selectedComponents
                }.map { $0.track }
                

                
                DispatchQueue.main.async {
                    self.tracks = filteredTracks
                    self.tableView.reloadData()
                }

            } catch {
                print("JSON parse error:", error)
            }
        }.resume()
    }

    
    @IBAction func fetchTracksTapped(_ sender: UIButton) {
        let selectedDate = datePicker.date
        fetchRecentlyPlayed(for: selectedDate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self

    }

}

    extension ViewController: ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            return self.view.window!
        }
    }

    struct TokenResponse: Decodable {
        let access_token: String
        let token_type: String
        let expires_in: Int
        let refresh_token: String?
    }
*/
