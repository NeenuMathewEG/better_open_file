import UIKit
import PDFKit

@objcMembers public class PdfPreviewViewController: UIViewController {
    private let pdfView = PDFView()
    private let pageBadge = UIView()
    private let pageLabel = UILabel()
    private let fileURL: URL
    private var didFitInitialPage = false
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

        setUpPageLabel(pageCount: document.pageCount)
        NotificationCenter.default.addObserver(self, selector: #selector(pageChanged), name: .PDFViewPageChanged, object: pdfView)
        updatePageLabel()
        NSLog("PDFDEBUG viewDidLoad pageCount=%d badgeHidden=%@ labelText=%@", document.pageCount, String(pageBadge.isHidden), pageLabel.text ?? "nil")
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("PDFDEBUG viewDidAppear badgeFrame=%@ badgeHidden=%@ badgeAlpha=%f labelText=%@ viewBounds=%@", NSCoder.string(for: pageBadge.frame), String(pageBadge.isHidden), pageBadge.alpha, pageLabel.text ?? "nil", NSCoder.string(for: view.bounds))
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

    private func setUpPageLabel(pageCount: Int) {
        pageLabel.text = "1 / \(pageCount)"
        pageLabel.textColor = .white
        pageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        pageLabel.textAlignment = .center
        pageLabel.translatesAutoresizingMaskIntoConstraints = false

        pageBadge.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        pageBadge.layer.cornerRadius = 12
        pageBadge.layer.masksToBounds = true
        pageBadge.isHidden = pageCount <= 1
        pageBadge.translatesAutoresizingMaskIntoConstraints = false

        pageBadge.addSubview(pageLabel)
        view.addSubview(pageBadge)
        NSLayoutConstraint.activate([
            pageLabel.topAnchor.constraint(equalTo: pageBadge.topAnchor, constant: 4),
            pageLabel.bottomAnchor.constraint(equalTo: pageBadge.bottomAnchor, constant: -4),
            pageLabel.leadingAnchor.constraint(equalTo: pageBadge.leadingAnchor, constant: 12),
            pageLabel.trailingAnchor.constraint(equalTo: pageBadge.trailingAnchor, constant: -12),

            pageBadge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageBadge.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            pageBadge.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            pageBadge.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
        ])
    }

    @objc private func pageChanged() {
        updatePageLabel()
        NSLog("PDFDEBUG pageChanged labelText=%@", pageLabel.text ?? "nil")
    }

    private func updatePageLabel() {
        guard let document = pdfView.document, let currentPage = pdfView.currentPage else {
            NSLog("PDFDEBUG updatePageLabel bailed out - document=%@ currentPage=%@", String(describing: pdfView.document), String(describing: pdfView.currentPage))
            return
        }
        pageLabel.text = "\(document.index(for: currentPage) + 1) / \(document.pageCount)"
    }

    @objc private func close() {
        dismiss(animated: true) { [weak self] in self?.onDismiss?() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
