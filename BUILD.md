# KENWOOD Remote

Builds are produced by GitHub Actions on every push. The IPA is unsigned so SideStore can sign/install it.

Current implementation uses the ExternalAccessory protocols extracted from the original KENWOOD Remote 1.9.4 IPA and retries EASession creation to handle modern iOS timing/readiness issues.
