import UIKit
import MessageUI
import ContactsUI

class ViewController: UIViewController,
                      UITableViewDelegate,
                      UITableViewDataSource,
                      MFMessageComposeViewControllerDelegate,
                      CNContactPickerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!

    var templates: [String] = []
    var selectedContactNumber: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadTemplates()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TemplateCell", for: indexPath)
        cell.textLabel?.text = templates[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTemplate = templates[indexPath.row]
        messageTextView.text = selectedTemplate
        if let selectedName = leftBarButton.title {
            nameTextField.text = selectedName
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            templates.remove(at: indexPath.row)
            saveTemplates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    func tableView(_ tableView: UITableView,
                   titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Sil"
    }
    
    func sendSMS(body: String) {
        guard MFMessageComposeViewController.canSendText() else {
            print("SMS gönderilemiyor")
            return
        }
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = self
        if let number = selectedContactNumber {
            composer.recipients = [number]
        }
        composer.body = body
        present(composer, animated: true)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

    func saveTemplates() {
        UserDefaults.standard.set(templates, forKey: "smsTemplates")
    }

    func loadTemplates() {
        if let saved = UserDefaults.standard.array(forKey: "smsTemplates") as? [String] {
            templates = saved
        } else {
            templates = [
                "Bilgilendirme: Bugünkü etkinlik iptal edilmiştir.",
                "Akşam yemeği için buluşalım mı?",
                "Bugün hava çok güzel, sahile inelim mi?",
                "Marketten bir şey lazım mı, çıkıyorum da?",
                "Film gecesi yapalım mı bu akşam?",
                "Kahve molası zamanı, eşlik etmek ister misin?",
                "Uyanınca mesaj at, kahvaltıya gidelim.",
                "Bugün moralim bozuk biraz, konuşabilir miyiz?",
                "Şarjım bitmek üzere, eve gelince yazarım.",
                "Yarın erkenden yürüyüşe çıkalım mı, hava serin olacakmış."
            ]

        }
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Bilinmeyen"
        leftBarButton.title = name

        if let phone = contact.phoneNumbers.first?.value.stringValue {
            selectedContactNumber = phone
        }

        nameTextField.text = name
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.borderColor = UIColor.systemGray6.cgColor
        messageTextView.layer.cornerRadius = 5
        messageTextView.clipsToBounds = true
    }

    @IBAction func selectContactButtonTapped(_ sender: UIBarButtonItem) {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        present(picker, animated: true)
    }
    
    @IBAction func addTemplateButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Yeni Şablon",
                                      message: "Mesaj içeriğini girin",
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Örn: Merhaba, randevunuz..."
        }
        alert.addAction(.init(title: "Ekle", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text,
                  !text.isEmpty else { return }
            self.templates.append(text)
            self.saveTemplates()
            self.tableView.reloadData()
        })
        alert.addAction(.init(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }
    
    @IBAction func sendSMSButtonTapped(_ sender: UIButton) {
        guard let text = messageTextView.text, !text.isEmpty else { return }
        sendSMS(body: text)
    }

}

