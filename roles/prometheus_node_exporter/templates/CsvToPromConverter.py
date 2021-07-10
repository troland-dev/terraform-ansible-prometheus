import datetime, os

forrasmappa_helye = "/etc/csvHorovodFile"
celmappa_helye = "/etc/csvToPromFile"

# 2021-07-07_14-22-59, ez a formátum lesz 
date = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")


uj_file = open(celmappa_helye + "/training.prom", "w", encoding="utf-8")

if os.path.exists(forrasmappa_helye + "/training.log") and os.path.isfile(forrasmappa_helye + "/training.log"):
    with open (forrasmappa_helye + "/training.log", "r", encoding="utf-8") as forrasfile:
        forrasfile.readline()
        for sor in forrasfile:
            sor = sor.strip("\n").split(",")
            uj_file.write("training_metrics{metric_type=\"loss\", epoch=\"" + sor[0] + "\"} " + sor[2] + "\n")
            uj_file.write("training_metrics{metric_type=\"acc\", epoch=\"" + sor[0] + "\"} " + sor[1] + "\n")

uj_file.close()

"""
epoch,accuracy,loss,lr
0,0.91365623,0.28287077,0.0013333333
->
training_metrics{metric_type=‘loss’, epoch=0} 0.895647
training_metrics{metric_type=’acc’, epoch=0} 0.96524
"""
