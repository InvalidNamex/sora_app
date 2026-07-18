import Flutter
import FirebaseAuth
import UIKit

class SceneDelegate: FlutterSceneDelegate {
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
