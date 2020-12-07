//
//  PokemonMoveView.swift
//  Presentation
//
//  Created by Luke Sadler on 24/08/2020.
//

import UIKit
import DataStore

protocol PokemonMoveViewDelegate: class {
    func pokemonMoveViewChangeButtonWasTapped(_ view: PokemonMoveView)
}

private struct GameNameNumber: Hashable {
    let name: String
    let number: Int
}

private typealias MoveDetails = (moveName: String?, genName:String, generationNumber: Int, levelLearnedAt: Int?)

class PokemonMoveView: XibLoadableView {

    weak var delegate: PokemonMoveViewDelegate?
    private var backgroundView: UIView!
    private var pickerView: UIPickerView?
    @IBOutlet private weak var tableview: UITableView!
    @IBOutlet private weak var genButton: UIButton!
    private let allGameNames: [GameNameNumber]
    private var selectedGame: GameNameNumber?

    private let generations: [MoveDetails]

    let moves: [PokemonDetailResponse.PokemonMove]
    var selectedGameMoves = [PokemonDetailResponse.PokemonMove]()

    init(moves: [PokemonDetailResponse.PokemonMove]) {
        self.moves = moves
        self.generations = []

        let gens = moves.compactMap({ moveDetails in
            moveDetails.versionGroupDetails.compactMap({ group -> MoveDetails in
                (moveDetails.move?.name,
                 group.versionGroup.name,
                 group.versionGroup.group,
                 group.levelLearnedAt)
            })
        })
        .reduce([], +)

        let allGamesAllMoves = gens
            .compactMap({ GameNameNumber(name: $0.genName, number: $0.generationNumber) })

        self.allGameNames = Array(Set(allGamesAllMoves))
            .sorted(by: { (lhs, rhs) -> Bool in
                lhs.number < rhs.number
            })

        super.init(frame: .zero)
        self.selectedGame = self.allGameNames.first
        updateButton()
        updateFilter()
        tableview.reloadData()
    }

    required init?(coder: NSCoder) {
        preconditionFailure("")
    }

    func updateButton () {
        self.genButton
            .setTitle(selectedGame?.name.apiNameFixed,
                      for: .normal)
    }

    @IBAction private
    func genTapped() {
        pickerView = UIPickerView()
        pickerView?.backgroundColor = .white
        pickerView?.dataSource = self
        pickerView?.delegate = self
        pickerView?.translatesAutoresizingMaskIntoConstraints = false
        self.superview?.addSubview(pickerView!)
        pickerView?.alpha = 0
        pickerView?.layer.borderColor = UIColor.darkGray.cgColor
        pickerView?.layer.borderWidth = 1

        //🤢
        superview?.superview?.superview?.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(tappedOut))
        )

        UIView.animate(withDuration: 0.3, animations: {
            self.pickerView?.alpha = 1
            // fade in backgroundview
        })

        pickerView?.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
        pickerView?.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
        pickerView?.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
    }

    @objc private
    func tappedOut () {
        pickerView?.removeFromSuperview()
        pickerView = nil
        updateButton()
    }

    private func updateFilter () {
        selectedGameMoves = moves
            .filter({ (move) -> Bool in
                let details = move.versionGroupDetails.filter({
                    $0.versionGroup.name == self.selectedGame?.name
                })
                return details.isEmpty == false
            })
            .sorted(by: { (lhs, rhs) -> Bool in

                let lhsLevel = lhs.versionGroupDetails.first?.levelLearnedAt
                let rhsLevel = rhs.versionGroupDetails.first?.levelLearnedAt

                if lhsLevel == 0 || lhsLevel == nil {
                    return false
                } else if rhsLevel == 0 || rhsLevel == nil {
                    return true
                } else {
                    return lhs.versionGroupDetails.first?.levelLearnedAt ?? -1 <
                        rhs.versionGroupDetails.first?.levelLearnedAt ?? -1
                }
            })
    }
}

extension PokemonMoveView: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { selectedGameMoves.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 60 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "cell")

        let moveObj = selectedGameMoves[indexPath.row]
        let name = moveObj.move?.name.capitalized

        let meta = moveObj.versionGroupDetails.first(where: { $0.versionGroup.name == selectedGame?.name })

        cell.textLabel?.text = name?.apiNameFixed ?? ""

        if let learnedAt = meta?.levelLearnedAt, learnedAt != 0 {
            cell.detailTextLabel?.text = "Learned at level \(learnedAt)"
        } else if let learnedVia = meta?.moveLearnMethod.name {
            cell.detailTextLabel?.text = "Learned via \(learnedVia)"
        } else {
            print("")
        }

        return cell
    }
}

extension PokemonMoveView: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        self.allGameNames.count
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        self.allGameNames[row].name.apiNameFixed
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedGame = allGameNames[row]
        updateFilter()
        tableview.reloadData()
    }
}
