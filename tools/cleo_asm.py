#!/usr/bin/env python3
"""
Tiny assembler for GTA Vice City CLEO scripts (.cs).

A CLEO .cs file is plain SCM bytecode: [opcode:uint16][params...].
Parameter encoding (from III.VC.CLEO source, CustomScript.h eParamType):
    0x01 int32   0x02 global var (uint16 byte offset)   0x03 local var (uint16 index)
    0x04 int8    0x05 int16                              0x06 float32
Jumps inside a CLEO script are encoded as NEGATIVE offsets relative to the
start of the script (CScript::JumpTo: ip = base - address when address < 0).

Usage:  python3 tools/cleo_asm.py            -> rebuilds mods/CLEO/*.cs
        python3 tools/cleo_asm.py --dump     -> also prints a hex listing
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "..", "mods", "CLEO")

# Global variables defined by the game's own main.scm (same in III / VC / SA)
PLAYER_CHAR = ("g", 2)   # $PLAYER_CHAR  -> byte offset 8
PLAYER_ACTOR = ("g", 3)  # $PLAYER_ACTOR -> byte offset 12


def lv(i):
    """local variable i@"""
    return ("l", i)


def lbl(name):
    return ("label", name)


class Asm:
    def __init__(self):
        self.items = []   # ("op", opcode, params) | ("label", name)

    def label(self, name):
        self.items.append(("label", name))

    def op(self, opcode, *params):
        self.items.append(("op", opcode, params))

    # --- encoding helpers -------------------------------------------------
    @staticmethod
    def _enc_int(v):
        if -128 <= v <= 127:
            return b"\x04" + struct.pack("<b", v)
        if -32768 <= v <= 32767:
            return b"\x05" + struct.pack("<h", v)
        return b"\x01" + struct.pack("<i", v)

    def _enc_param(self, p, labels):
        if isinstance(p, bool):
            return self._enc_int(int(p))
        if isinstance(p, int):
            return self._enc_int(p)
        if isinstance(p, float):
            return b"\x06" + struct.pack("<f", p)
        kind = p[0]
        if kind == "g":
            return b"\x02" + struct.pack("<H", p[1] * 4)
        if kind == "l":
            return b"\x03" + struct.pack("<H", p[1])
        if kind == "label":
            off = labels[p[1]]
            if off == 0:
                raise ValueError("label at offset 0 cannot be encoded (would be an absolute jump)")
            return b"\x01" + struct.pack("<i", -off)
        raise ValueError("bad param %r" % (p,))

    def _size_param(self, p):
        if isinstance(p, bool):
            return 2
        if isinstance(p, int):
            return len(self._enc_int(p))
        if isinstance(p, float):
            return 5
        return {"g": 3, "l": 3, "label": 5}[p[0]]

    def assemble(self):
        # pass 1: label offsets
        labels, off = {}, 0
        for it in self.items:
            if it[0] == "label":
                labels[it[1]] = off
            else:
                off += 2 + sum(self._size_param(p) for p in it[2])
        # pass 2: bytes
        out = bytearray()
        for it in self.items:
            if it[0] == "label":
                continue
            out += struct.pack("<H", it[1])
            for p in it[2]:
                out += self._enc_param(p, labels)
        return bytes(out), labels


# ---------------------------------------------------------------------------
# Opcodes used (numbers verified against the Sanny Builder VC opcode library)
WAIT = 0x0001                      # wait <ms>
GOTO = 0x0002                      # jump <label>
SET_LVAR_INT = 0x0006              # i@ = int
SUB_VAL_FROM_INT_LVAR = 0x000E     # i@ -= int
MULT_INT_LVAR_BY_VAL = 0x0012      # i@ *= int
IS_INT_LVAR_GREATER_THAN = 0x0019  # i@ > int
IS_INT_LVAR_EQUAL = 0x0039         # i@ == int
GOTO_IF_FALSE = 0x004D             # jf <label>
IF = 0x00D6                        # if <n>  (0 = single condition)
IS_CHAR_IN_ANY_CAR = 0x00DF        # actor driving
ADD_SCORE = 0x0109                 # player money += int
STORE_SCORE = 0x010B               # i@ = player money
IS_CAR_DEAD = 0x0119               # car wrecked / handle invalid
SET_PLAYER_HEALTH = 0x0222
SET_CAR_HEALTH = 0x0224
GET_CHAR_HEALTH = 0x0226
IS_PLAYER_PLAYING = 0x0256         # player defined (alive, not busted)
SET_CHAR_PROOFS = 0x02AB           # actor immunities BP FP EP CP MP
SET_CHAR_CANT_BE_DRAGGED_OUT = 0x039E   # nobody can pull the actor off / out of a vehicle
SET_CAR_CAN_BE_DAMAGED = 0x03F5    # 0 = CBike::VehicleDamage returns early -> no collision knock-off
IS_PLAYER_ON_ANY_BIKE = 0x047E
SET_CAN_BURST_CAR_TYRES = 0x053F   # 0 = no burst -> no CBike::BurstTyre knock-off
GIVE_WEAPON_TO_PLAYER = 0x01B1     # player, weaponType, ammo (adds ammo if already owned)
REQUEST_MODEL = 0x0247
MARK_MODEL_AS_NO_LONGER_NEEDED = 0x0249
LOAD_ALL_MODELS_NOW = 0x038B
SET_PLAYER_NEVER_GETS_TIRED = 0x0330
GET_AMMO_IN_PLAYER_WEAPON = 0x0419 # player, weaponType -> ammo
GET_CURRENT_CHAR_WEAPON = 0x0470   # actor -> weaponType

# weaponType (eWeaponType) and the model id the game must have loaded before giving it
WEAPONS = [
    (10, 268),  # katana
    (12, 270),  # grenade
    (18, 275),  # python
    (20, 278),  # spas12 shotgun
    (25, 284),  # mp5
    (26, 280),  # m4
    (29, 286),  # laserscope sniper rifle
    (30, 287),  # rocket launcher
]
AMMO = 30000
SET_CAR_PROOFS = 0x02AC            # car immunities  BP FP EP CP MP
ADD_ARMOUR_TO_CHAR = 0x035F
STORE_CAR_CHAR_IS_IN_NO_SAVE = 0x03C0

MONEY_TARGET = 99_999_999          # 8 digits: the most the HUD displays cleanly


def build_infinite_health():
    """
    Every frame: keep Tommy at full health & armour, make him bullet / fire /
    explosion / collision / melee proof, and make whatever car he is in
    indestructible (proofs are removed again when he leaves the car).
    """
    a = Asm()
    a.op(SET_LVAR_INT, lv(1), 0)                 # 1@ = 0  (car currently proofed?)  -- also keeps LOOP off offset 0
    a.label("LOOP")
    a.op(WAIT, 0)
    a.op(IF, 0)
    a.op(IS_PLAYER_PLAYING, PLAYER_CHAR)
    a.op(GOTO_IF_FALSE, lbl("LOOP"))

    # heal only when needed so a bigger max health (150 after Paramedic) is never lowered
    a.op(GET_CHAR_HEALTH, PLAYER_ACTOR, lv(2))   # 2@ = health
    a.op(IF, 0)
    a.op(IS_INT_LVAR_GREATER_THAN, lv(2), 99)
    a.op(GOTO_IF_FALSE, lbl("HEAL"))
    a.op(GOTO, lbl("PROOFS"))
    a.label("HEAL")
    a.op(SET_PLAYER_HEALTH, PLAYER_CHAR, 100)
    a.label("PROOFS")
    a.op(ADD_ARMOUR_TO_CHAR, PLAYER_ACTOR, 100)  # game clamps armour at its maximum
    a.op(SET_CHAR_PROOFS, PLAYER_ACTOR, 1, 1, 1, 1, 1)

    # vehicle handling
    a.op(IF, 0)
    a.op(IS_CHAR_IN_ANY_CAR, PLAYER_ACTOR)
    a.op(GOTO_IF_FALSE, lbl("NOT_IN_CAR"))
    a.op(STORE_CAR_CHAR_IS_IN_NO_SAVE, PLAYER_ACTOR, lv(0))   # 0@ = car
    a.op(SET_CAR_PROOFS, lv(0), 1, 1, 1, 1, 1)
    a.op(SET_CAR_HEALTH, lv(0), 1000)
    a.op(SET_LVAR_INT, lv(1), 1)
    a.op(GOTO, lbl("LOOP"))

    a.label("NOT_IN_CAR")
    a.op(IF, 0)
    a.op(IS_INT_LVAR_EQUAL, lv(1), 1)            # did we proof a car earlier?
    a.op(GOTO_IF_FALSE, lbl("LOOP"))
    a.op(IF, 0)
    a.op(IS_CAR_DEAD, lv(0))                     # gone or wrecked -> nothing to undo
    a.op(GOTO_IF_FALSE, lbl("UNPROOF"))
    a.op(SET_LVAR_INT, lv(1), 0)
    a.op(GOTO, lbl("LOOP"))
    a.label("UNPROOF")
    a.op(SET_CAR_PROOFS, lv(0), 0, 0, 0, 0, 0)
    a.op(SET_LVAR_INT, lv(1), 0)
    a.op(GOTO, lbl("LOOP"))
    return a


def build_infinite_money():
    """
    Twice a second: top the wallet back up to MONEY_TARGET.
    money += (TARGET - money)  computed without any compare:
        0@ = money ; 0@ -= TARGET ; 0@ *= -1 ; money += 0@
    """
    a = Asm()
    a.op(SET_LVAR_INT, lv(0), 0)                 # keeps LOOP off offset 0
    a.label("LOOP")
    a.op(WAIT, 500)
    a.op(IF, 0)
    a.op(IS_PLAYER_PLAYING, PLAYER_CHAR)
    a.op(GOTO_IF_FALSE, lbl("LOOP"))
    a.op(STORE_SCORE, PLAYER_CHAR, lv(0))
    a.op(SUB_VAL_FROM_INT_LVAR, lv(0), MONEY_TARGET)
    a.op(MULT_INT_LVAR_BY_VAL, lv(0), -1)
    a.op(ADD_SCORE, PLAYER_CHAR, lv(0))
    a.op(GOTO, lbl("LOOP"))
    return a


def build_no_bike_fall():
    """
    Never get knocked off a bike. In the game code a rider is thrown off in
    CBike::VehicleDamage (skipped entirely when the bike can't be damaged),
    CBike::BurstTyre (never runs when tyres can't burst) and when a ped drags
    the rider off (blocked by 'can't be dragged out'). All three are flipped
    while the player is on a bike and flipped back when he gets off.
    """
    a = Asm()
    a.op(SET_LVAR_INT, lv(1), 0)                 # 1@ = 0  (flags applied?)  -- keeps LOOP off offset 0
    a.label("LOOP")
    a.op(WAIT, 0)
    a.op(IF, 0)
    a.op(IS_PLAYER_PLAYING, PLAYER_CHAR)
    a.op(GOTO_IF_FALSE, lbl("LOOP"))
    a.op(IF, 0)
    a.op(IS_PLAYER_ON_ANY_BIKE, PLAYER_CHAR)
    a.op(GOTO_IF_FALSE, lbl("NOT_ON_BIKE"))
    a.op(STORE_CAR_CHAR_IS_IN_NO_SAVE, PLAYER_ACTOR, lv(0))   # 0@ = bike
    a.op(SET_CAR_CAN_BE_DAMAGED, lv(0), 0)
    a.op(SET_CAN_BURST_CAR_TYRES, lv(0), 0)
    a.op(SET_CHAR_CANT_BE_DRAGGED_OUT, PLAYER_ACTOR, 1)
    a.op(SET_LVAR_INT, lv(1), 1)
    a.op(GOTO, lbl("LOOP"))

    a.label("NOT_ON_BIKE")
    a.op(IF, 0)
    a.op(IS_INT_LVAR_EQUAL, lv(1), 1)
    a.op(GOTO_IF_FALSE, lbl("LOOP"))
    a.op(SET_CHAR_CANT_BE_DRAGGED_OUT, PLAYER_ACTOR, 0)
    a.op(SET_LVAR_INT, lv(1), 0)
    a.op(IF, 0)
    a.op(IS_CAR_DEAD, lv(0))                     # bike gone -> nothing to undo
    a.op(GOTO_IF_FALSE, lbl("UNDO"))
    a.op(GOTO, lbl("LOOP"))
    a.label("UNDO")
    a.op(SET_CAR_CAN_BE_DAMAGED, lv(0), 1)
    a.op(SET_CAN_BURST_CAR_TYRES, lv(0), 1)
    a.op(GOTO, lbl("LOOP"))
    return a


def build_all_weapons():
    """
    All weapons + infinite ammo.
    Once per life: load the weapon models, hand out one weapon per slot.
    Every second: read the weapon in hand; if its ammo is below 3000, give it
    again (the game adds the ammo to the same slot, so guns you pick up on
    the street are refilled too, not replaced).
    """
    a = Asm()
    a.op(SET_LVAR_INT, lv(1), 0)                 # 1@ = weapons handed out this life?
    a.label("LOOP")
    a.op(WAIT, 1000)
    a.op(IF, 0)
    a.op(IS_PLAYER_PLAYING, PLAYER_CHAR)
    a.op(GOTO_IF_FALSE, lbl("NOT_PLAYING"))
    a.op(IF, 0)
    a.op(IS_INT_LVAR_EQUAL, lv(1), 1)
    a.op(GOTO_IF_FALSE, lbl("GIVE"))
    # refill the weapon in hand
    a.op(GET_CURRENT_CHAR_WEAPON, PLAYER_ACTOR, lv(2))   # 2@ = type
    a.op(IF, 0)
    a.op(IS_INT_LVAR_GREATER_THAN, lv(2), 0)    # unarmed -> nothing to refill
    a.op(GOTO_IF_FALSE, lbl("LOOP"))
    a.op(GET_AMMO_IN_PLAYER_WEAPON, PLAYER_CHAR, lv(2), lv(3))   # 3@ = ammo
    a.op(IF, 0)
    a.op(IS_INT_LVAR_GREATER_THAN, lv(3), 2999)
    a.op(GOTO_IF_FALSE, lbl("REFILL"))
    a.op(GOTO, lbl("LOOP"))
    a.label("REFILL")
    a.op(GIVE_WEAPON_TO_PLAYER, PLAYER_CHAR, lv(2), AMMO)
    a.op(GOTO, lbl("LOOP"))

    a.label("NOT_PLAYING")                       # wasted / busted: weapons are gone, hand out again next time
    a.op(SET_LVAR_INT, lv(1), 0)
    a.op(GOTO, lbl("LOOP"))

    a.label("GIVE")
    for _, model in WEAPONS:
        a.op(REQUEST_MODEL, model)
    a.op(LOAD_ALL_MODELS_NOW)
    for wtype, _ in WEAPONS:
        a.op(GIVE_WEAPON_TO_PLAYER, PLAYER_CHAR, wtype, AMMO)
    for _, model in WEAPONS:
        a.op(MARK_MODEL_AS_NO_LONGER_NEEDED, model)
    a.op(SET_LVAR_INT, lv(1), 1)
    a.op(GOTO, lbl("LOOP"))
    return a


def build_infinite_sprint():
    a = Asm()
    a.op(SET_LVAR_INT, lv(0), 0)
    a.label("LOOP")
    a.op(WAIT, 1000)
    a.op(IF, 0)
    a.op(IS_PLAYER_PLAYING, PLAYER_CHAR)
    a.op(GOTO_IF_FALSE, lbl("LOOP"))
    a.op(SET_PLAYER_NEVER_GETS_TIRED, PLAYER_CHAR, 1)
    a.op(GOTO, lbl("LOOP"))
    return a


def build_no_dragout():
    """Nobody can pull Tommy out of a car (or off a bike). Every frame, so it
    also wins over no_bike_fall.cs resetting the flag when leaving a bike."""
    a = Asm()
    a.op(SET_LVAR_INT, lv(0), 0)
    a.label("LOOP")
    a.op(WAIT, 0)
    a.op(IF, 0)
    a.op(IS_PLAYER_PLAYING, PLAYER_CHAR)
    a.op(GOTO_IF_FALSE, lbl("LOOP"))
    a.op(SET_CHAR_CANT_BE_DRAGGED_OUT, PLAYER_ACTOR, 1)
    a.op(GOTO, lbl("LOOP"))
    return a


SCRIPTS = {
    "all_weapons.cs": build_all_weapons,
    "infinite_sprint.cs": build_infinite_sprint,
    "no_dragout.cs": build_no_dragout,
    "no_bike_fall.cs": build_no_bike_fall,
    "infinite_health.cs": build_infinite_health,
    "infinite_money.cs": build_infinite_money,
}


def main():
    dump = "--dump" in sys.argv
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, builder in SCRIPTS.items():
        data, labels = builder().assemble()
        path = os.path.join(OUT_DIR, name)
        with open(path, "wb") as f:
            f.write(data)
        print("wrote %s (%d bytes) labels=%s" % (os.path.relpath(path), len(data), labels))
        if dump:
            print(data.hex(" "))


if __name__ == "__main__":
    main()
