import Flutter
import FirebaseAuth
import UIKit
import app_links

class SceneDelegate: FlutterSceneDelegate {
	override func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		// With the UIScene lifecycle, a universal link that launches a
		// terminated app is delivered here rather than through AppDelegate's
		// application(_:continue:restorationHandler:). app_links 6.x only
		// observes the application callback, so cache the launch URL explicitly
		// for getInitialLink() before Flutter asks for it.
		for userActivity in connectionOptions.userActivities {
			guard
				userActivity.activityType == NSUserActivityTypeBrowsingWeb,
				let url = userActivity.webpageURL
			else {
				continue
			}

			AppLinks.shared.handleLink(url: url)
			break
		}

		super.scene(
			scene,
			willConnectTo: session,
			options: connectionOptions
		)
	}

	override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		for context in URLContexts {
			if Auth.auth().canHandle(context.url) {
				NSLog("[SoraAuth] Firebase Auth handled scene URL callback: \(context.url.scheme ?? "no-scheme")")
				return
			}
		}
		NSLog("[SoraAuth] Scene URL callbacks were not handled by Firebase Auth.")
		super.scene(scene, openURLContexts: URLContexts)
	}
}
