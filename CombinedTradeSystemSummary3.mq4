void CalculateWeightedSignalDistribution(string symbol, double &longPercent, double &shortPercent, double &holdPercent)
{
    // Bu şekilde tanımlama yerine:
    // double weights[6] = {Weight_W1, Weight_D1, Weight_H4, Weight_H1, Weight_M30, Weight_M15};
    
    // Bu şekilde yapalım:
    double weights[6];
    weights[0] = Weight_W1;
    weights[1] = Weight_D1;
    weights[2] = Weight_H4;
    weights[3] = Weight_H1;
    weights[4] = Weight_M30;
    weights[5] = Weight_M15;
    
    // ... fonksiyonun geri kalanı aynı kalacak ...
}
