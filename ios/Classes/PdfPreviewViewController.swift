import UIKit
import PDFKit

@objcMembers public class PdfPreviewViewController: UIViewController {
    private let pdfView = PDFView()
    private let fileURL: URL
    public var onDismiss: (() -> Void)?

    public init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }
    public required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let document = PDFDocument(url: fileURL) else { return }

        // Force eager page-geometry computation before first layout. PDFKit
        // otherwise computes page bounds lazily as pages scroll into view,
        // and recalculating content size mid-zoom on a large/complex page
        // is what causes the scroll offset to snap to a stale page.
        for i in 0..<document.pageCount {
            _ = document.page(at: i)?.bounds(for: .cropBox)
        }

        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
    }

    @objc private func close() {
        dismiss(animated: true) { [weak self] in self?.onDismiss?() }
    }
}
