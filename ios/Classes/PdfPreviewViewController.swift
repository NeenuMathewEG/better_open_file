import UIKit
import PDFKit

@objcMembers public class PdfPreviewViewController: UIViewController {
    private let pdfView = PDFView()
    private let titleLabel = UILabel()
    private let pageLabel = UILabel()
    private let fileURL: URL
    private let displayName: String
    private var didFitInitialPage = false
    public var onDismiss: (() -> Void)?

    public init(fileURL: URL, displayName: String) {
        self.fileURL = fileURL
        self.displayName = displayName
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

        setUpTitleView(pageCount: document.pageCount)
        NotificationCenter.default.addObserver(self, selector: #selector(pageChanged), name: .PDFViewPageChanged, object: pdfView)
        updatePageLabel()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // PDFKit computes autoScales against pdfView's bounds at the moment the
        // property is set, which above is still CGRect.zero (Auto Layout hasn't
        // run yet). That leaves scaleFactor at 1.0 - the page rendered far
        // smaller than the screen. Re-fit once the view has its real size.
        guard !didFitInitialPage, pdfView.bounds.width > 0 else { return }
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        didFitInitialPage = true
    }

    // Mirrors the Quick Look / Files.app document preview title: filename in
    // bold with the page count as a smaller subtitle underneath.
    private func setUpTitleView(pageCount: Int) {
        titleLabel.text = displayName
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingMiddle

        pageLabel.font = .systemFont(ofSize: 12)
        pageLabel.textColor = .secondaryLabel
        pageLabel.textAlignment = .center
        pageLabel.isHidden = pageCount <= 1
        pageLabel.text = "1 of \(pageCount)"

        let stack = UIStackView(arrangedSubviews: [titleLabel, pageLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(lessThanOrEqualToConstant: 220).isActive = true

        navigationItem.titleView = stack
    }

    @objc private func pageChanged() {
        updatePageLabel()
    }

    private func updatePageLabel() {
        guard let document = pdfView.document, let currentPage = pdfView.currentPage else { return }
        pageLabel.text = "\(document.index(for: currentPage) + 1) of \(document.pageCount)"
    }

    @objc private func close() {
        dismiss(animated: true) { [weak self] in self?.onDismiss?() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
