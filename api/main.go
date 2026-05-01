package main

import (
	"encoding/json"
	"math"
	"net/http"
)

type Player struct {
	Position   string  `json:"position"`
	SkillLevel float64 `json:"skill_level"`
}

type MatchRequest struct {
	User    Player   `json:"user"`
	Players []Player `json:"players"`
}

type MatchResponse struct {
	MatchScore int `json:"match_score"`
}

func calculateMatch(w http.ResponseWriter, r *http.Request) {
	var req MatchRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var avgSkill float64
	if len(req.Players) > 0 {
		for _, p := range req.Players {
			avgSkill += p.SkillLevel
		}
		avgSkill /= float64(len(req.Players))
	} else {
		avgSkill = req.User.SkillLevel 
	}

	skillDiff := math.Abs(req.User.SkillLevel - avgSkill)
	skillScore := math.Max(0, 100-skillDiff)

	posCount := 0
	for _, p := range req.Players {
		if p.Position == req.User.Position {
			posCount++
		}
	}
	
	posScore := 100.0
	if posCount >= 2 {
		posScore = 60.0
	}

	finalScore := (skillScore * 0.7) + (posScore * 0.3)

	json.NewEncoder(w).Encode(MatchResponse{MatchScore: int(finalScore)})
}

func main() {
	http.HandleFunc("/api/match-quality", calculateMatch)
	http.ListenAndServe(":8080", nil)
}